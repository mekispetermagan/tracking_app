from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from routers import auth, admin, mentor, shared
from routers._photos import COMPRESSED_PHOTO_DIR

app = FastAPI(title="Progress Tracking API")

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(mentor.router, prefix="/api/mentor", tags=["mentor"])
app.include_router(shared.router, prefix="/api/shared", tags=["shared"])

@app.get("/api/health")
def health_check():
    return {"status": "ok"}

app.mount(
    "/compressed_photos",
    StaticFiles(
        directory=COMPRESSED_PHOTO_DIR,
    ),
    name="compressed_photos",
)
