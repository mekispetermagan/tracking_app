from io import BytesIO
from pathlib import Path
from secrets import randbelow

from fastapi import HTTPException, UploadFile
from PIL import (
    Image,
    ImageOps,
    UnidentifiedImageError,
)

from models import SessionPhoto
from schemas.photos import SessionPhotoOut


BACKEND_DIR = Path(__file__).resolve().parents[1]

ORIGINAL_PHOTO_DIR = (
    BACKEND_DIR / "original_photos"
)
COMPRESSED_PHOTO_DIR = (
    BACKEND_DIR / "compressed_photos"
)

ORIGINAL_STORY_PHOTO_DIR = (
    BACKEND_DIR / "original_story_photos"
)
COMPRESSED_STORY_PHOTO_DIR = (
    BACKEND_DIR / "compressed_story_photos"
)

for directory in (
    ORIGINAL_PHOTO_DIR,
    COMPRESSED_PHOTO_DIR,
    ORIGINAL_STORY_PHOTO_DIR,
    COMPRESSED_STORY_PHOTO_DIR,
):
    directory.mkdir(
        parents=True,
        exist_ok=True,
    )

MAX_PHOTO_SIZE = 12 * 1024 * 1024
COMPRESSED_MAX_SIZE = (720, 480)
COMPRESSED_QUALITY = 70

EXTENSIONS = {
    "JPEG": ".jpg",
    "PNG": ".png",
    "WEBP": ".webp",
}


def photo_to_out(
    photo: SessionPhoto,
) -> SessionPhotoOut:
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


def delete_photo_files(
    paths: list[Path],
):
    for path in paths:
        path.unlink(missing_ok=True)


def _convert_to_rgb(
    image: Image.Image,
) -> Image.Image:
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


async def _read_photo(
    upload: UploadFile,
) -> tuple[bytes, str, Image.Image]:
    data = await upload.read(
        MAX_PHOTO_SIZE + 1,
    )

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
        with Image.open(
            BytesIO(data),
        ) as source:
            image_format = source.format

            if image_format not in EXTENSIONS:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "Unsupported photo format"
                    ),
                )

            source.load()

            compressed_image = (
                ImageOps.exif_transpose(
                    source,
                ).copy()
            )

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

    return (
        data,
        image_format,
        compressed_image,
    )


def _filename_available(
    stem: str,
    original_directory: Path,
    compressed_directory: Path,
) -> bool:
    return (
        not any(
            original_directory.glob(
                f"{stem}.*",
            )
        )
        and not any(
            compressed_directory.glob(
                f"{stem}.*",
            )
        )
    )


def _create_session_filename_stem(
    course_id: int,
    session_date,
    mentor_profile_id: int,
    photo_number: int,
) -> str:
    while True:
        random_number = randbelow(
            1_000_000,
        )

        stem = (
            f"{course_id:02d}_"
            f"{session_date:%Y%m%d}_"
            f"{mentor_profile_id:02d}_"
            f"{photo_number:02d}_"
            f"{random_number:06d}"
        )

        if _filename_available(
            stem,
            ORIGINAL_PHOTO_DIR,
            COMPRESSED_PHOTO_DIR,
        ):
            return stem


def _create_story_filename_stem(
    story_id: int,
    submission_date,
    mentor_profile_id: int,
) -> str:
    while True:
        random_number = randbelow(
            1_000_000,
        )

        stem = (
            f"{story_id:02d}_"
            f"{submission_date:%Y%m%d}_"
            f"{mentor_profile_id:02d}_"
            f"{random_number:06d}"
        )

        if _filename_available(
            stem,
            ORIGINAL_STORY_PHOTO_DIR,
            COMPRESSED_STORY_PHOTO_DIR,
        ):
            return stem


def _write_photo(
    *,
    data: bytes,
    image_format: str,
    compressed_image: Image.Image,
    stem: str,
    original_directory: Path,
    compressed_directory: Path,
    original_relative_directory: str,
    compressed_relative_directory: str,
) -> tuple[str, str, list[Path]]:
    original_filename = (
        f"{stem}{EXTENSIONS[image_format]}"
    )
    compressed_filename = f"{stem}.jpg"

    original_absolute_path = (
        original_directory
        / original_filename
    )
    compressed_absolute_path = (
        compressed_directory
        / compressed_filename
    )

    try:
        with original_absolute_path.open(
            "xb",
        ) as file:
            file.write(data)

        with compressed_absolute_path.open(
            "xb",
        ) as file:
            compressed_image.save(
                file,
                format="JPEG",
                quality=COMPRESSED_QUALITY,
                optimize=True,
            )

    except Exception:
        original_absolute_path.unlink(
            missing_ok=True,
        )
        compressed_absolute_path.unlink(
            missing_ok=True,
        )
        raise

    return (
        (
            f"{original_relative_directory}/"
            f"{original_filename}"
        ),
        (
            f"{compressed_relative_directory}/"
            f"{compressed_filename}"
        ),
        [
            original_absolute_path,
            compressed_absolute_path,
        ],
    )


async def store_photo(
    upload: UploadFile,
    course_id: int,
    session_date,
    mentor_profile_id: int,
    photo_number: int,
) -> tuple[str, str, list[Path]]:
    (
        data,
        image_format,
        compressed_image,
    ) = await _read_photo(upload)

    stem = _create_session_filename_stem(
        course_id=course_id,
        session_date=session_date,
        mentor_profile_id=(
            mentor_profile_id
        ),
        photo_number=photo_number,
    )

    return _write_photo(
        data=data,
        image_format=image_format,
        compressed_image=compressed_image,
        stem=stem,
        original_directory=(
            ORIGINAL_PHOTO_DIR
        ),
        compressed_directory=(
            COMPRESSED_PHOTO_DIR
        ),
        original_relative_directory=(
            "original_photos"
        ),
        compressed_relative_directory=(
            "compressed_photos"
        ),
    )


async def store_story_photo(
    upload: UploadFile,
    story_id: int,
    submission_date,
    mentor_profile_id: int,
) -> tuple[str, str, list[Path]]:
    (
        data,
        image_format,
        compressed_image,
    ) = await _read_photo(upload)

    stem = _create_story_filename_stem(
        story_id=story_id,
        submission_date=submission_date,
        mentor_profile_id=(
            mentor_profile_id
        ),
    )

    return _write_photo(
        data=data,
        image_format=image_format,
        compressed_image=compressed_image,
        stem=stem,
        original_directory=(
            ORIGINAL_STORY_PHOTO_DIR
        ),
        compressed_directory=(
            COMPRESSED_STORY_PHOTO_DIR
        ),
        original_relative_directory=(
            "original_story_photos"
        ),
        compressed_relative_directory=(
            "compressed_story_photos"
        ),
    )
