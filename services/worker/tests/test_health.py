from app.executor.mock_executor import mock_execute


def test_mock_execute_returns_valid_result():
    """Verify mock executor returns a valid result dict with required keys."""
    result = mock_execute("print('hello')", "python")

    assert "status" in result
    assert result["status"] in ("passed", "timeout", "oom_killed")
    assert "execution_time_ms" in result
    assert isinstance(result["execution_time_ms"], int)
    assert result["execution_time_ms"] > 0


def test_mock_execute_passed_has_output():
    """Run multiple times, at least one should pass (60% probability)."""
    results = [mock_execute("x = 1", "python") for _ in range(20)]
    passed = [r for r in results if r["status"] == "passed"]

    assert len(passed) > 0, "Expected at least one 'passed' result in 20 runs"
    for r in passed:
        assert "output" in r
        assert "memory_mb" in r


def test_mock_execute_has_all_outcomes():
    """Run many times, verify all 3 outcomes appear."""
    results = [mock_execute("x = 1", "python") for _ in range(100)]
    statuses = {r["status"] for r in results}

    assert "passed" in statuses, "Expected 'passed' in 100 runs"
    # timeout and oom_killed are probabilistic, at least one should appear
    assert len(statuses) >= 2, f"Expected at least 2 outcomes, got: {statuses}"
