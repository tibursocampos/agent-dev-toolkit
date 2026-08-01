# Async pitfalls (Python)

> Load when writing `async def`, using asyncio, or choosing sync vs async endpoints (FastAPI, httpx, DB drivers). Complements `fastapi.md` and `typing.md`.

---

## MUST

- Use `async def` only when the function awaits I/O or the project standardizes on async call graphs end-to-end.
- `await` every coroutine; never fire-and-forget without an explicit task strategy the project already uses.
- Propagate cancellation and timeouts with `asyncio.timeout` / project helpers; do not hang forever on external calls.
- Use **async-native** clients in async code (e.g. `httpx.AsyncClient`, async DB drivers) — do not call blocking I/O on the event loop.
- Offload unavoidable blocking work with `asyncio.to_thread()` (or the project’s executor pattern), not by nesting sync calls in hot async paths.
- Close async resources with `async with` / explicit `aclose()`; pair lifespan shutdown with startup.
- In tests, use the project’s pytest-asyncio (or trio) mode; mark async tests as neighbors do.

---

## MUST NOT

- Call `.result()`, `.wait()`, or `asyncio.run()` inside an already-running event loop.
- Mix `time.sleep()` into async handlers — use `asyncio.sleep()`.
- Create a new event loop per request or per unit of work when a framework loop already exists.
- Share a single non-thread-safe client/session across tasks without the project’s documented pattern.
- Swallow `CancelledError` (or BaseException) in broad `except Exception` blocks.
- Mark Flask-style sync apps fully async without an explicit migration (Quart/ASGI) ask.
- Use `async def` endpoints that only call sync ORM/HTTP and block the worker under load.

---

## Prefer when matching repo

| Situation | Prefer |
|-----------|--------|
| FastAPI + sync SQLAlchemy | Sync path operations **or** run sync DB in `to_thread` / sync routes — match existing style |
| FastAPI + async SQLAlchemy / databases | `async def` + async session dependency |
| httpx | `AsyncClient` inside async routes; sync `Client` in sync routes |
| Background work | Framework `BackgroundTasks`, ARQ/Celery/RQ already in repo — not ad-hoc `create_task` storms |
| Concurrency | `asyncio.gather` with bounded semaphores when the project limits fan-out |
| Locks | `asyncio.Lock` for async-critical sections; never thread locks across awaits without care |

### Common failure modes

```python
# Wrong — blocks the event loop
async def get_user(id: int) -> User:
    time.sleep(0.1)           # blocks
    return sync_client.get(id)  # blocking I/O

# Prefer — async client
async def get_user(id: int) -> User:
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return parse(response)

# Wrong — nested asyncio.run
async def handler() -> None:
    asyncio.run(other())  # RuntimeError / deadlock risk

# Prefer — await directly
async def handler() -> None:
    await other()
```

### Sync vs async decision

1. If neighbors are sync → stay sync unless the change requires async I/O throughout.
2. If neighbors are async → stay async; wrap leftover blocking calls.
3. Do not create a half-async service layer that deadlocks under the framework’s loop.

### Task and cancellation checklist

- [ ] No `asyncio.run` inside framework handlers
- [ ] No `time.sleep` / sync HTTP/DB on the event loop
- [ ] Timeouts on outbound I/O
- [ ] Tasks created with `create_task` are tracked/awaited or use the project supervisor
- [ ] `CancelledError` not swallowed
- [ ] Async tests use the project’s pytest-asyncio mode

### Gathering safely

```python
async def fetch_many(urls: list[str]) -> list[bytes]:
    sem = asyncio.Semaphore(8)  # match project limits

    async def one(url: str) -> bytes:
        async with sem:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url)
                response.raise_for_status()
                return response.content

    return list(await asyncio.gather(*(one(u) for u in urls)))
```

---

## References

- [asyncio — Coroutines and Tasks](https://docs.python.org/3/library/asyncio-task.html)
- [FastAPI — Concurrency and async / await](https://fastapi.tiangolo.com/async/)
- [httpx — Async support](https://www.python-httpx.org/async/)
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/en/latest/)
