from fastapi import FastAPI

from routers.auth import router as auth_router

app = FastAPI(title="Progress Tracking API")

app.include_router(auth_router, prefix="/api/auth", tags=["auth"])


@app.get("/api/health")
def health_check():
    return {"status": "ok"}