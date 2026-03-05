import logging
import os
import random
import time

logger = logging.getLogger(__name__)

MOCK_EXEC_TIMEOUT = int(os.getenv("MOCK_EXEC_TIMEOUT", "5"))
MOCK_EXEC_MAX_MEMORY_MB = int(os.getenv("MOCK_EXEC_MAX_MEMORY_MB", "512"))


def mock_execute(code: str, language: str) -> dict:
    """
    Simulate code execution with random outcomes:
      - 60% passed (light CPU, 1-3s)
      - 25% timeout (heavy CPU, exceeds timeout)
      - 15% oom_killed (memory bomb)
    CPU/RAM usage is REAL to test K8s resource limits and HPA.
    """
    roll = random.random()

    if roll < 0.60:
        return _execute_passed(code, language)
    elif roll < 0.85:
        return _execute_timeout(code, language)
    else:
        return _execute_oom(code, language)


def _execute_passed(code: str, language: str) -> dict:
    """Light CPU burn, 1-3 seconds."""
    burn_seconds = random.uniform(1.0, 3.0)
    start = time.time()

    # Real CPU work
    counter = 0
    while time.time() - start < burn_seconds:
        counter += 1
        _ = counter * counter

    elapsed_ms = int((time.time() - start) * 1000)
    logger.info(f"Mock execute: PASSED, cpu_time={elapsed_ms}ms, \
        language={language}")

    return {
        "status": "passed",
        "execution_time_ms": elapsed_ms,
        "memory_mb": random.randint(16, 64),
        "output": "mock output: all test cases passed",
    }


def _execute_timeout(code: str, language: str) -> dict:
    """Heavy CPU burn, exceeds timeout threshold."""
    start = time.time()
    timeout_seconds = MOCK_EXEC_TIMEOUT + random.uniform(0.5, 2.0)

    # Real CPU work — burns CPU until timeout
    counter = 0
    while time.time() - start < timeout_seconds:
        counter += 1
        _ = counter**2 + counter**3  # heavier computation

    elapsed_ms = int((time.time() - start) * 1000)
    logger.warning(
        f"Mock execute: TIMEOUT, cpu_time={elapsed_ms}ms, \
            limit={MOCK_EXEC_TIMEOUT}s"
    )

    return {
        "status": "timeout",
        "execution_time_ms": elapsed_ms,
        "memory_mb": random.randint(32, 128),
        "error": f"Execution exceeded {MOCK_EXEC_TIMEOUT}s time limit",
    }


def _execute_oom(code: str, language: str) -> dict:
    """Allocate large memory to simulate OOM. Real memory usage."""
    start = time.time()
    target_mb = min(MOCK_EXEC_MAX_MEMORY_MB, random.randint(256, 512))

    try:
        # Allocate real memory — each element in list is ~28 bytes (Python int)
        # 1MB ≈ 37500 ints
        elements = target_mb * 37500
        memory_hog = [random.randint(0, 1000000) for _ in range(elements)]
        time.sleep(0.5)  # hold memory briefly
        del memory_hog
    except MemoryError:
        pass

    elapsed_ms = int((time.time() - start) * 1000)
    logger.warning(
        f"Mock execute: OOM_KILLED, memory={target_mb}MB, \
            cpu_time={elapsed_ms}ms"
    )

    return {
        "status": "oom_killed",
        "execution_time_ms": elapsed_ms,
        "memory_mb": target_mb,
        "error": f"Process killed: memory limit exceeded ({target_mb}MB)",
    }
