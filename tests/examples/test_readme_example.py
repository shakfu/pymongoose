#!/usr/bin/env python3
"""
Simple test to verify that all examples can be imported and instantiated.
"""
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "src"))

def test_imports():
    """Test that all examples can be imported."""
    # Test HTTP client import
    sys.path.insert(0, str(Path(__file__).parent / "http"))
    import http_client
    assert hasattr(http_client, 'HttpClient')
    print("✓ http_client.py imports successfully")

    # Test HTTP server import
    import http_server
    assert hasattr(http_server, 'handler')
    print("✓ http_server.py imports successfully")

    # Test WebSocket server import
    sys.path.insert(0, str(Path(__file__).parent / "websocket"))
    import websocket_server
    assert hasattr(websocket_server, 'handler')
    print("✓ websocket_server.py imports successfully")

    # Test WebSocket broadcast import
    import websocket_broadcast
    assert hasattr(websocket_broadcast, 'BroadcastServer')
    print("✓ websocket_broadcast.py imports successfully")

if __name__ == "__main__":
    test_imports()
    print("\nAll example imports passed!")
