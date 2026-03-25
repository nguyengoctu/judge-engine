import io
import logging
import os
import tarfile
import time
import uuid

import docker
from docker.errors import ImageNotFound, APIError

logger = logging.getLogger(__name__)

# Runner image mapping
LANGUAGE_IMAGES = {
    "python": "judge-runner-python:latest",
    "javascript": "judge-runner-javascript:latest",
    "java": "judge-runner-java:latest",
}

# File extensions per language
LANGUAGE_EXTENSIONS = {
    "python": "solution.py",
    "javascript": "solution.js",
    "java": "Solution.java",
}

# Command to run code per language
LANGUAGE_COMMANDS = {
    "python": ["python", "/code/solution.py"],
    "javascript": ["node", "/code/solution.js"],
    "java": [
        "sh",
        "-c",
        "cd /tmp && cp /code/Solution.java . \
             && javac Solution.java && java Solution",
    ],
}

# Sandbox config from env
SANDBOX_MEMORY_LIMIT = os.getenv("SANDBOX_MEMORY_LIMIT", "256m")
SANDBOX_CPU_LIMIT = float(os.getenv("SANDBOX_CPU_LIMIT", "0.5"))
SANDBOX_TIMEOUT = int(os.getenv("SANDBOX_TIMEOUT", "10"))
SANDBOX_PIDS_LIMIT = int(os.getenv("SANDBOX_PIDS_LIMIT", "50"))


def get_docker_client():
    """Get Docker client connected via socket. Retries for DinD sidecar."""
    import time

    max_retries = 30
    for attempt in range(max_retries):
        try:
            client = docker.from_env()
            if attempt > 0:
                logger.info(f"Docker daemon connected after {attempt}s")
            return client
        except docker.errors.DockerException:
            if attempt < max_retries - 1:
                time.sleep(1)
            else:
                raise


def _make_tar(filename: str, code: str) -> bytes:
    """Create an in-memory tar archive containing the code file."""
    data = code.encode("utf-8")
    tar_stream = io.BytesIO()
    with tarfile.open(fileobj=tar_stream, mode="w") as tar:
        info = tarfile.TarInfo(name=filename)
        info.size = len(data)
        info.mode = 0o644
        tar.addfile(info, io.BytesIO(data))
    tar_stream.seek(0)
    return tar_stream.read()


def pull_runner_images():
    """Pre-pull runner images on startup to avoid cold-start delays."""
    client = get_docker_client()
    for language, image in LANGUAGE_IMAGES.items():
        try:
            client.images.get(image)
            logger.info(f"Runner image ready: {image}")
        except ImageNotFound:
            logger.warning(
                f"Runner image {image} not found locally. "
                f"Build it with: docker build -t {image} \
                            -f docker/runners/Dockerfile.{language} \
                            docker/runners/"
            )
    client.close()


def docker_execute(code: str, language: str) -> dict:
    """
    Execute user code inside an isolated Docker container.

    Uses put_archive to inject code
    (avoids Docker-in-Docker volume mount issues).
    Returns dict with: status, execution_time_ms, memory_mb, output/error
    """
    if language not in LANGUAGE_IMAGES:
        return {
            "status": "error",
            "execution_time_ms": 0,
            "memory_mb": 0,
            "error": f"Unsupported language: {language}",
        }

    image = LANGUAGE_IMAGES[language]
    filename = LANGUAGE_EXTENSIONS[language]
    command = LANGUAGE_COMMANDS[language]
    client = get_docker_client()
    container_name = f"judge-{uuid.uuid4().hex[:12]}"

    start_time = time.time()

    try:
        # Create container (don't start yet)
        container = client.containers.create(
            image=image,
            command=command,
            name=container_name,
            # Resource limits
            mem_limit=SANDBOX_MEMORY_LIMIT,
            nano_cpus=int(SANDBOX_CPU_LIMIT * 1e9),
            pids_limit=SANDBOX_PIDS_LIMIT,
            # Security
            network_mode="none",
            cap_drop=["ALL"],
            security_opt=["no-new-privileges"],
            # Filesystem — writable so we can inject code
            # Java can compile in /tmp
            tmpfs={"/tmp": "rw,exec,size=10m"},
        )

        # Inject code into container via tar archive
        # (avoids DinD volume issues)
        tar_data = _make_tar(filename, code)
        container.put_archive("/code", tar_data)

        # Start container
        container.start()

        # Wait for container to finish with timeout
        try:
            result = container.wait(timeout=SANDBOX_TIMEOUT)
            exit_code = result.get("StatusCode", -1)
        except Exception:
            # Timeout — kill container
            logger.warning(
                f"Container {container_name} \
                timed out after {SANDBOX_TIMEOUT}s"
            )
            try:
                container.kill()
            except Exception:
                pass
            exit_code = 124  # timeout

        elapsed_ms = int((time.time() - start_time) * 1000)

        # Capture output
        try:
            stdout = (
                container.logs(stdout=True, stderr=False)
                .decode("utf-8", errors="replace")
                .strip()
            )
            stderr = (
                container.logs(stdout=False, stderr=True)
                .decode("utf-8", errors="replace")
                .strip()
            )
        except Exception:
            stdout = ""
            stderr = ""

        # Get memory stats
        memory_mb = 0
        try:
            stats = container.stats(stream=False)
            memory_mb = int(
                stats
                .get("memory_stats", {})
                .get("max_usage", 0) / (1024 * 1024)
            )
        except Exception:
            pass

        # Cleanup container
        try:
            container.remove(force=True)
        except Exception:
            pass

        # Map exit code to status
        status = _map_exit_code(exit_code)

        # 137 is almost always OOM
        if exit_code == 137:
            status = "oom_killed"

        result_dict = {
            "status": status,
            "execution_time_ms": elapsed_ms,
            "memory_mb": memory_mb,
        }

        if status == "passed":
            result_dict["output"] = stdout[:10000]  # cap output
        else:
            result_dict["error"] = (
                stderr[:5000] if stderr else f"Exit code: {exit_code}"
            )
            if stdout:
                result_dict["output"] = stdout[:5000]

        logger.info(
            f"Docker executor: {status}, exit_code={exit_code}, "
            f"time={elapsed_ms}ms, memory={memory_mb}MB, language={language}"
        )

        return result_dict

    except ImageNotFound:
        return {
            "status": "error",
            "execution_time_ms": 0,
            "memory_mb": 0,
            "error": f"Runner image not found: {image}. Build it first.",
        }
    except APIError as e:
        logger.error(f"Docker API error: {e}")
        return {
            "status": "error",
            "execution_time_ms": int((time.time() - start_time) * 1000),
            "memory_mb": 0,
            "error": f"Docker error: {str(e)[:500]}",
        }
    finally:
        client.close()


def _map_exit_code(exit_code: int) -> str:
    """Map container exit code to submission status."""
    if exit_code == 0:
        return "passed"
    elif exit_code == 124:
        return "timeout"
    elif exit_code == 137:
        return "oom_killed"
    else:
        return "failed"
