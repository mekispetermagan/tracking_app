from fastapi import FastAPI

from routers import auth, admin, mentor, shared

app = FastAPI(title="Progress Tracking API")

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(mentor.router, prefix="/api/mentor", tags=["mentor"])
app.include_router(shared.router, prefix="/api/shared", tags=["shared"])

@app.get("/api/health")
def health_check():
    return {"status": "ok"}