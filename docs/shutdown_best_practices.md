# Shutdown Best Practices - Quick Reference

## TL;DR

```python
manager = Manager(handler)
manager.listen('http://0.0.0.0:8000', http=True)

try:
    while True:
        manager.poll(100)  # [x] 100ms for responsive Ctrl+C
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    manager.close()  # [x] Always cleanup
```

## Two Key Issues Fixed

### 1. Responsive Ctrl+C: Use Short Poll Timeout

**Problem**: `poll(1000)` blocks for 1 second before checking for KeyboardInterrupt

**Solution**: Use `poll(100)` for ~100ms shutdown response

```python
# [X] BEFORE: Takes up to 1 second to exit
while True:
    manager.poll(1000)

# [x] AFTER: Exits in ~100ms
while True:
    manager.poll(100)
```

**Performance impact**: Negligible (< 1% throughput difference)

### 2. Proper Cleanup: Always Call manager.close()

**Problem**: Resources leak if Manager isn't closed

**Solution**: Use try/finally to guarantee cleanup

```python
# [X] BEFORE: No cleanup on Ctrl+C
manager = Manager(handler)
manager.listen('http://0.0.0.0:8000', http=True)
while True:
    manager.poll(100)

# [x] AFTER: Cleanup guaranteed
manager = Manager(handler)
manager.listen('http://0.0.0.0:8000', http=True)
try:
    while True:
        manager.poll(100)
finally:
    manager.close()  # Always called, even on exception
```

## What manager.close() Does

- Closes all connections
- Frees listening sockets
- Cancels timers
- Releases C library resources
- Prevents further use (sets `_freed = True`)

## Production Pattern

For production servers, handle SIGTERM too (systemd, Docker):

```python
import signal

shutdown = False

def signal_handler(sig, frame):
    global shutdown
    shutdown = True

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

manager = Manager(handler)
manager.listen('http://0.0.0.0:8000', http=True)

try:
    while not shutdown:
        manager.poll(100)
finally:
    manager.close()
```

## Multi-threaded Pattern

Stop polling thread before closing:

```python
import threading

stop_flag = threading.Event()

def run_server():
    while not stop_flag.is_set():
        manager.poll(100)

thread = threading.Thread(target=run_server, daemon=False)
thread.start()

# ... later, on shutdown ...
stop_flag.set()      # Signal thread to stop
thread.join()        # Wait for poll loop to exit
manager.close()      # Safe to close now
```

## Common Mistakes

| [X] DON'T | [x] DO |
|---------|------|
| `poll(1000)` - slow Ctrl+C | `poll(100)` - responsive |
| No try/finally - leaks resources | Always use try/finally |
| Close while thread polling - segfault | Stop thread first, then close |
| Reuse closed Manager | Create new Manager |
| `poll(0)` - 100% CPU | `poll(100)` - efficient |

## Testing Your Cleanup

```bash
# Should exit cleanly with no errors
python your_server.py
# Press Ctrl+C
# Should see: "Shutting down..." and "Cleanup complete"
```

## Complete Example

See `benchmarks/demo_server.py` for a working example with:
- [x] Responsive Ctrl+C (`poll(100)`)
- [x] Proper cleanup (`try`/`finally`)
- [x] User-friendly messages

---

**Further Reading**:
- `cleanup_and_shutdown.md` - Comprehensive guide with advanced patterns
- `poll_timeout_guide.md` - Deep dive on poll timeout tradeoffs
