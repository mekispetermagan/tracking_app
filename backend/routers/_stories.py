from datetime import UTC, date, datetime

from models import (
    MentorProfile,
    Story,
    StoryOfMonth,
)
from schemas.stories import (
    AdminStoryOut,
    MentorStoryOut,
    StoryOutBase,
    StoryPhotoOut,
    StoryWinnerOut,
)


def normalize_month(
    value: date,
) -> date:
    return value.replace(day=1)


def current_month() -> date:
    return datetime.now(
        UTC,
    ).date().replace(day=1)


def mentor_has_active_course(
    mentor: MentorProfile,
) -> bool:
    return any(
        course.active
        for course in mentor.courses
    )


def mentor_can_rate_story(
    story: Story,
    mentor: MentorProfile,
) -> bool:
    return (
        story.active
        and story.submitted_by_mentor_profile_id
        != mentor.id
        and story.submission_month
        == current_month()
        and mentor.active
        and mentor.account.active
        and mentor_has_active_course(mentor)
    )


def story_photo_to_out(
    story: Story,
) -> StoryPhotoOut:
    if story.photo is None:
        raise RuntimeError(
            "Story has no photo",
        )

    return StoryPhotoOut(
        id=story.photo.id,
        url=f"/{story.photo.compressed_path}",
        uploaded_at=story.photo.uploaded_at,
    )


def story_base_to_out(
    story: Story,
) -> StoryOutBase:
    account = story.submitted_by.account

    return StoryOutBase(
        id=story.id,
        text=story.text,
        course_id=story.course_id,
        course_name=story.course.name,
        submitted_by_mentor_profile_id=(
            story.submitted_by_mentor_profile_id
        ),
        submitter_first_name=(
            account.first_name
        ),
        submitter_last_name=(
            account.last_name
        ),
        submission_month=(
            story.submission_month
        ),
        photo=story_photo_to_out(story),
        is_winner=(
            story.story_of_month is not None
        ),
        created_at=story.created_at,
        updated_at=story.updated_at,
    )


def mentor_story_to_out(
    story: Story,
    mentor: MentorProfile,
) -> MentorStoryOut:
    my_rating = next(
        (
            rating.rating
            for rating in story.ratings
            if rating.mentor_profile_id
            == mentor.id
        ),
        None,
    )

    base = story_base_to_out(
        story,
    )

    return MentorStoryOut(
        **base.model_dump(),
        my_rating=my_rating,
        can_rate=mentor_can_rate_story(
            story,
            mentor,
        ),
    )


def admin_story_to_out(
    story: Story,
) -> AdminStoryOut:
    rating_count = len(
        story.ratings,
    )

    average_rating = None

    if rating_count:
        average_rating = round(
            sum(
                rating.rating
                for rating in story.ratings
            )
            / rating_count,
            2,
        )

    base = story_base_to_out(
        story,
    )

    return AdminStoryOut(
        **base.model_dump(),
        active=story.active,
        rating_count=rating_count,
        average_rating=average_rating,
    )


def story_winner_to_out(
    winner: StoryOfMonth,
) -> StoryWinnerOut:
    return StoryWinnerOut(
        month=winner.month,
        selected_at=winner.selected_at,
        story=story_base_to_out(
            winner.story,
        ),
    )
