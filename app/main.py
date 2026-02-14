from fastapi import FastAPI


app = FastAPI(title="cibus-api", version="1.0.0")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/v1/message")
def get_message() -> dict[str, str]:
    return {"message": "Hello from cibus API"}
