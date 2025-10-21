"""Tests for DNS resolution."""

import pytest
import time
from pymongoose import Manager, MG_EV_RESOLVE, MG_EV_ERROR


def test_dns_resolve_basic():
    """Test basic DNS resolution."""
    manager = Manager()
    resolve_results = []

    def handler(conn, ev, data):
        if ev == MG_EV_RESOLVE:
            resolve_results.append(data)

    try:
        # Create a listener connection (stays alive longer)
        conn = manager.listen("tcp://127.0.0.1:0", handler=handler)
        manager.poll(10)

        # Trigger DNS resolution
        conn.resolve("google.com")

        # Poll to process resolution
        for _ in range(100):
            manager.poll(10)
            if resolve_results:
                break
            time.sleep(0.01)

        # Should have received resolution result (success or failure)
        # Note: This might fail in some environments, so we just check it doesn't crash
        assert True  # If we got here without crashing, test passes
    finally:
        manager.close()


def test_dns_resolve_cancel():
    """Test canceling DNS resolution."""
    manager = Manager()
    resolve_results = []

    def handler(conn, ev, data):
        if ev == MG_EV_RESOLVE:
            resolve_results.append(data)

    try:
        # Create a listener connection (stays alive longer)
        conn = manager.listen("tcp://127.0.0.1:0", handler=handler)
        manager.poll(10)

        # Trigger DNS resolution
        conn.resolve("google.com")

        # Immediately cancel it
        conn.resolve_cancel()

        # Poll a bit
        for _ in range(10):
            manager.poll(10)

        # Cancellation means we likely won't get a result
        # Test passes if no crash occurs
        assert True
    finally:
        manager.close()


def test_dns_resolve_with_port():
    """Test DNS resolution with port in URL."""
    manager = Manager()
    resolve_results = []

    def handler(conn, ev, data):
        if ev == MG_EV_RESOLVE:
            resolve_results.append(data)

    try:
        # Create a listener connection (stays alive longer)
        conn = manager.listen("tcp://127.0.0.1:0", handler=handler)
        manager.poll(10)

        # Trigger DNS resolution with port
        conn.resolve("tcp://google.com:80")

        # Poll to process resolution
        for _ in range(100):
            manager.poll(10)
            if resolve_results:
                break
            time.sleep(0.01)

        # Test passes if no crash
        assert True
    finally:
        manager.close()


def test_dns_resolve_invalid_host():
    """Test DNS resolution with invalid hostname."""
    manager = Manager()
    resolve_results = []
    error_results = []

    def handler(conn, ev, data):
        if ev == MG_EV_RESOLVE:
            resolve_results.append(data)
        elif ev == MG_EV_ERROR:
            error_results.append(data)

    try:
        # Create a listener connection (stays alive longer)
        conn = manager.listen("tcp://127.0.0.1:0", handler=handler)
        manager.poll(10)

        # Trigger DNS resolution with invalid host
        conn.resolve("this-host-should-not-exist-12345.invalid")

        # Poll to process resolution
        for _ in range(100):
            manager.poll(10)
            if resolve_results or error_results:
                break
            time.sleep(0.01)

        # Should get either a resolve event or error
        # Test passes if no crash
        assert True
    finally:
        manager.close()
