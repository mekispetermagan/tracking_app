from io import BytesIO
from pathlib import Path
from secrets import randbelow

from fastapi import HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

from models import SessionPhoto
from schemas.photos import SessionPhotoOut


BACKEND_DIR = Path(__file__).resolve().parents[1]

ORIGINAL_PHOTO_DIR = BACKEND_DIR / "original_photos"
COMPRESSED_PHOTO_DIR = BACKEND_DIR / "compressed_photos"

ORIGINAL_PHOTO_DIR.mkdir(parents=True, exist_ok=True)
COMPRESSED_PHOTO_DIR.mkdir(parents=True, exist_ok=True)

MAX_PHOTO_SIZE = 12 * 1024 * 1024
COMPRESSED_MAX_SIZE = (720, 480)
COMPRESSED_QUALITY = 70

EXTENSIONS = {
    "JPEG": ".jpg",
    "PNG": ".png",
    "WEBP": ".webp",
}


def photo_to_out(photo: SessionPhoto) -> SessionPhotoOut:
    return SessionPhotoOut(
        id=photo.id,
        session_log_id=photo.session_log_id,
        mentor_profile_id=photo.mentor_profile_id,
        mentor_name=(
            f"{photo.mentor.account.first_name} "
            f"{photo.mentor.account.last_name}"
        ),
        session_date=photo.session_log.date,
        photo_number=photo.photo_number,
        url=f"/{photo.compressed_path}",
        uploaded_at=photo.uploaded_at,
    )


def delete_photo_files(paths: list[Path]):
    for path in paths:
        path.unlink(missing_ok=True)


def _convert_to_rgb(image: Image.Image) -> Image.Image:
    if image.mode in ("RGBA", "LA"):
        rgba = image.convert("RGBA")
        background = Image.new(
            "RGB",
            rgba.size,
            "white",
        )
        background.paste(
            rgba,
            mask=rgba.getchannel("A"),
        )
        return background

    return image.convert("RGB")


def _create_filename_stem(
    course_id: int,
    session_date,
    mentor_profile_id: int,
    photo_number: int,
) -> str:
    while True:
        random_number = randbelow(1_000_000)

        stem = (
            f"{course_id:02d}_"
            f"{session_date:%Y%m%d}_"
            f"{mentor_profile_id:02d}_"
            f"{photo_number:02d}_"
            f"{random_number:06d}"
        )

        if not any(
            ORIGINAL_PHOTO_DIR.glob(f"{stem}.*")
        ) and not any(
            COMPRESSED_PHOTO_DIR.glob(f"{stem}.*")
        ):
            return stem


async def store_photo(
    upload: UploadFile,
    course_id: int,
    session_date,
    mentor_profile_id: int,
    photo_number: int,
) -> tuple[str, str, list[Path]]:
    data = await upload.read(MAX_PHOTO_SIZE + 1)

    if not data:
        raise HTTPException(
            status_code=400,
            detail="Photo file is empty",
        )

    if len(data) > MAX_PHOTO_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Photo file is too large",
        )

    try:
        with Image.open(BytesIO(data)) as source:
            image_format = source.format

            if image_format not in EXTENSIONS:
                raise HTTPException(
                    status_code=400,
                    detail="Unsupported photo format",
                )

            source.load()

            compressed_image = ImageOps.exif_transpose(
                source,
            ).copy()

    except HTTPException:
        raise
    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombError,
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid photo file",
        )

    compressed_image.thumbnail(
        COMPRESSED_MAX_SIZE,
        Image.Resampling.LANCZOS,
    )
    compressed_image = _convert_to_rgb(
        compressed_image,
    )

    stem = _create_filename_stem(
        course_id=course_id,
        session_date=session_date,
        mentor_profile_id=mentor_profile_id,
        photo_number=photo_number,
    )

    original_filename = (
        f"{stem}{EXTENSIONS[image_format]}"
    )
    compressed_filename = f"{stem}.jpg"

    original_absolute_path = (
        ORIGINAL_PHOTO_DIR / original_filename
    )
    compressed_absolute_path = (
        COMPRESSED_PHOTO_DIR / compressed_filename
    )

    try:
        with original_absolute_path.open("xb") as file:
            file.write(data)

        with compressed_absolute_path.open("xb") as file:
            compressed_image.save(
                file,
                format="JPEG",
                quality=COMPRESSED_QUALITY,
                optimize=True,
            )

    except Exception:
        original_absolute_path.unlink(missing_ok=True)
        compressed_absolute_path.unlink(missing_ok=True)
        raise

    return (
        f"original_photos/{original_filename}",
        f"compressed_photos/{compressed_filename}",
        [
            original_absolute_path,
            compressed_absolute_path,
        ],
    )
