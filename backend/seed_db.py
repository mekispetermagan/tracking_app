from datetime import UTC, date, datetime, time, timedelta
from math import ceil, floor
from random import Random

from pwdlib import PasswordHash

from config import settings
from database import Base, engine, SessionLocal
from models import (
    Account,
    AdminProfile,
    CompletionStatus,
    Country,
    Course,
    MentorProfile,
    ProjectType,
    SessionLog,
    SessionLogMentor,
    SessionLogMentorRole,
    SessionPhoto,
    Student,
)

password_hash = PasswordHash.recommended()
random = Random(20260714)

SESSION_START = date(2026, 5, 10)
SESSION_END = date(2026, 7, 10)

PHOTO_FILENAMES = (
    "01_20260510_01_01_538223.jpg",
    "01_20260510_01_02_184906.jpg",
    "01_20260510_01_03_772451.jpg",
)

SKILL_GAMES = (
    "Mixed letters",
    "Missing letters",
    "Reading game",
    "Bible game",
    "Shopping game",
    "Logic game",
    "Math train",
    "Number swarm",
    "Guess the operator",
    "Even odd game",
    "Balance game",
    "Word card memory",
    "Number card memory",
)

WHAT_WORKED = (
    "Most students completed the main task independently.",
    "Pair work helped students solve problems together.",
    "Students understood the new blocks and components quickly.",
    "The demonstration followed by practice worked well.",
)

CHALLENGES = (
    None,
    "Some students needed extra help with sequencing.",
    "A few students needed more time for debugging.",
    "Different working speeds made it difficult to finish together.",
)

NEXT_STEPS = (
    "Continue with a more complex version of the project.",
    "Repeat the difficult step before starting the next project.",
    "Add one new feature and allow more time for testing.",
    "Review the main concept at the beginning of the next session.",
)


def hash_secret(secret: str) -> str:
    return password_hash.hash(secret)


def get_or_create_uganda(db):
    country = db.query(Country).filter_by(name="Uganda").first()

    if not country:
        country = Country(code="UG", name="Uganda")
        db.add(country)
        db.flush()

    return country


def add_account(
    db,
    first_name,
    last_name,
    phone,
    country_id,
    mentor_pin=None,
    admin_password=None,
):
    account = Account(
        first_name=first_name,
        last_name=last_name,
        phone=phone,
        country_id=country_id,
        preferred_language="en",
    )
    db.add(account)
    db.flush()

    expiry = datetime.now(UTC) + timedelta(
        days=settings.temporary_secret_days,
    )

    if mentor_pin:
        db.add(
            MentorProfile(
                account_id=account.id,
                pin_hash=hash_secret(mentor_pin),
                must_change_pin=True,
                temporary_pin_expires_at=expiry,
            )
        )

    if admin_password:
        db.add(
            AdminProfile(
                account_id=account.id,
                password_hash=hash_secret(admin_password),
                must_change_password=True,
                temporary_password_expires_at=expiry,
            )
        )

    return account


def get_mentor_profile(db, first_name, last_name):
    return (
        db.query(MentorProfile)
        .join(Account)
        .filter(
            Account.first_name == first_name,
            Account.last_name == last_name,
        )
        .one()
    )


def add_course_with_students(
    db,
    name,
    description,
    country_id,
    day_of_week,
    start_time,
    mentors,
    students,
):
    course = Course(
        name=name,
        description=description,
        country_id=country_id,
        day_of_week=day_of_week,
        start_time=start_time,
        mentors=mentors,
    )
    db.add(course)
    db.flush()

    for student_data in students:
        student = Student(
            first_name=student_data["first_name"],
            last_name=student_data["last_name"],
            origin_country_id=country_id,
            birth_year=student_data["birth_year"],
            gender=student_data["gender"],
            courses=[course],
        )
        db.add(student)

    return course


def matching_course_dates(day_of_week):
    current = SESSION_START
    current += timedelta(
        days=(day_of_week - current.weekday()) % 7,
    )

    dates = []

    while current <= SESSION_END:
        dates.append(current)
        current += timedelta(days=7)

    return dates


def session_mentor_data(index, mentors):
    if not mentors:
        raise ValueError(
            "Session log requires at least one mentor.",
        )

    primary = mentors[index % len(mentors)]

    if len(mentors) == 1:
        return (
            primary,
            [
                SessionLogMentor(
                    mentor=primary,
                    role=SessionLogMentorRole.TEACHING,
                ),
            ],
        )

    secondary = mentors[(index + 1) % len(mentors)]
    pattern = index % 4

    if pattern == 0:
        return (
            primary,
            [
                SessionLogMentor(
                    mentor=primary,
                    role=SessionLogMentorRole.TEACHING,
                ),
                SessionLogMentor(
                    mentor=secondary,
                    role=SessionLogMentorRole.SUPPORTING,
                ),
            ],
        )

    if pattern == 1:
        return (
            primary,
            [
                SessionLogMentor(
                    mentor=primary,
                    role=SessionLogMentorRole.TEACHING,
                ),
            ],
        )

    if pattern == 2:
        return (
            primary,
            [
                SessionLogMentor(
                    mentor=primary,
                    role=SessionLogMentorRole.TEACHING,
                ),
                SessionLogMentor(
                    mentor=secondary,
                    role=SessionLogMentorRole.TEACHING,
                ),
            ],
        )

    return (
        secondary,
        [
            SessionLogMentor(
                mentor=primary,
                role=SessionLogMentorRole.SUPPORTING,
            ),
            SessionLogMentor(
                mentor=secondary,
                role=SessionLogMentorRole.TEACHING,
            ),
        ],
    )


def add_session_logs(db, course, mentors, projects):
    dates = matching_course_dates(course.day_of_week)

    if len(projects) > len(dates):
        raise ValueError(
            f"{course.name} has {len(projects)} projects but only "
            f"{len(dates)} matching dates."
        )

    students = list(course.students)

    minimum_attendance = ceil(len(students) * 0.5)
    maximum_attendance = floor(len(students) * 0.9)

    statuses = (
        CompletionStatus.COMPLETED,
        CompletionStatus.COMPLETED,
        CompletionStatus.PARTLY_COMPLETED,
        CompletionStatus.COMPLETED,
        CompletionStatus.PARTLY_COMPLETED,
        CompletionStatus.NOT_COMPLETED,
    )

    session_logs = []

    for index, (project_type, project_title) in enumerate(
        projects,
    ):
        attendance_count = random.randint(
            minimum_attendance,
            maximum_attendance,
        )

        submitted_by, mentor_participations = (
            session_mentor_data(index, mentors)
        )

        session_log = SessionLog(
            submitted_by=submitted_by,
            mentor_participations=mentor_participations,
            course=course,
            date=dates[index],
            project_title=project_title,
            project_type=project_type,
            other_project_type=None,
            games_played=SKILL_GAMES[
                index % len(SKILL_GAMES)
            ],
            completion_status=statuses[
                index % len(statuses)
            ],
            what_worked=WHAT_WORKED[
                index % len(WHAT_WORKED)
            ],
            challenges=CHALLENGES[
                index % len(CHALLENGES)
            ],
            next_step=NEXT_STEPS[
                index % len(NEXT_STEPS)
            ],
            students=random.sample(
                students,
                attendance_count,
            ),
        )

        db.add(session_log)
        session_logs.append(session_log)

    return session_logs


def add_photo_submission(
    db,
    session_log,
    mentor,
    filenames,
):
    if len(filenames) != 3:
        raise ValueError(
            "Photo submission must contain exactly three photos.",
        )

    if not any(
        participation.mentor is mentor
        for participation in session_log.mentor_participations
    ):
        raise ValueError(
            "Photo uploader must be a participating mentor.",
        )

    for photo_number, filename in enumerate(
        filenames,
        start=1,
    ):
        db.add(
            SessionPhoto(
                session_log=session_log,
                mentor=mentor,
                photo_number=photo_number,
                original_path=f"original_photos/{filename}",
                compressed_path=f"compressed_photos/{filename}",
            )
        )


def main():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        uganda = get_or_create_uganda(db)

        add_account(
            db,
            "Abdallah",
            "Kiggundu",
            "0712345678",
            uganda.id,
            mentor_pin="123456",
        )
        add_account(
            db,
            "Margret",
            "Nakalema",
            "0774231538",
            uganda.id,
            mentor_pin="123456",
            admin_password="Margret123",
        )
        add_account(
            db,
            "Peter",
            "Mekis",
            "0781653508",
            uganda.id,
            admin_password="Peter123",
        )

        abdallah = get_mentor_profile(
            db,
            "Abdallah",
            "Kiggundu",
        )
        margret = get_mentor_profile(
            db,
            "Margret",
            "Nakalema",
        )

        shared_mentors = [abdallah, margret]

        hillside = add_course_with_students(
            db=db,
            name="Hillside Katalemwa",
            description=(
                "Digital education course at "
                "Hillside Katalemwa."
            ),
            country_id=uganda.id,
            day_of_week=6,
            start_time=time(14, 0),
            mentors=shared_mentors,
            students=[
                {
                    "first_name": "Aisha",
                    "last_name": "Namutebi",
                    "birth_year": 2014,
                    "gender": "F",
                },
                {
                    "first_name": "Brenda",
                    "last_name": "Nakato",
                    "birth_year": 2015,
                    "gender": "F",
                },
                {
                    "first_name": "Claire",
                    "last_name": "Nabunya",
                    "birth_year": 2014,
                    "gender": "F",
                },
                {
                    "first_name": "Doreen",
                    "last_name": "Nansubuga",
                    "birth_year": 2013,
                    "gender": "F",
                },
                {
                    "first_name": "Esther",
                    "last_name": "Namukasa",
                    "birth_year": 2015,
                    "gender": "F",
                },
                {
                    "first_name": "Brian",
                    "last_name": "Sserwadda",
                    "birth_year": 2014,
                    "gender": "M",
                },
                {
                    "first_name": "Daniel",
                    "last_name": "Kato",
                    "birth_year": 2013,
                    "gender": "M",
                },
                {
                    "first_name": "Emmanuel",
                    "last_name": "Mugisha",
                    "birth_year": 2015,
                    "gender": "M",
                },
                {
                    "first_name": "Isaac",
                    "last_name": "Lwanga",
                    "birth_year": 2014,
                    "gender": "M",
                },
                {
                    "first_name": "Joshua",
                    "last_name": "Mutebi",
                    "birth_year": 2013,
                    "gender": "M",
                },
            ],
        )

        cdi = add_course_with_students(
            db=db,
            name="CDI Luwero",
            description=(
                "Digital education course in Luwero with "
                "Change Development Initiatives."
            ),
            country_id=uganda.id,
            day_of_week=5,
            start_time=time(10, 0),
            mentors=shared_mentors,
            students=[
                {
                    "first_name": "Faith",
                    "last_name": "Nakalema",
                    "birth_year": 2014,
                    "gender": "F",
                },
                {
                    "first_name": "Gloria",
                    "last_name": "Nabirye",
                    "birth_year": 2015,
                    "gender": "F",
                },
                {
                    "first_name": "Joan",
                    "last_name": "Namugga",
                    "birth_year": 2014,
                    "gender": "F",
                },
                {
                    "first_name": "Mercy",
                    "last_name": "Akello",
                    "birth_year": 2013,
                    "gender": "F",
                },
                {
                    "first_name": "Sarah",
                    "last_name": "Nakku",
                    "birth_year": 2015,
                    "gender": "F",
                },
                {
                    "first_name": "Aaron",
                    "last_name": "Kisembo",
                    "birth_year": 2014,
                    "gender": "M",
                },
                {
                    "first_name": "David",
                    "last_name": "Mukasa",
                    "birth_year": 2013,
                    "gender": "M",
                },
                {
                    "first_name": "Ivan",
                    "last_name": "Sekidde",
                    "birth_year": 2015,
                    "gender": "M",
                },
                {
                    "first_name": "Martin",
                    "last_name": "Kiggundu",
                    "birth_year": 2014,
                    "gender": "M",
                },
                {
                    "first_name": "Samuel",
                    "last_name": "Nsubuga",
                    "birth_year": 2013,
                    "gender": "M",
                },
            ],
        )

        db.flush()

        hillside_logs = add_session_logs(
            db,
            hillside,
            shared_mentors,
            [
                (
                    ProjectType.SCRATCH,
                    "Dancing animation",
                ),
                (
                    ProjectType.SCRATCH,
                    "Crazy letters",
                ),
                (
                    ProjectType.SCRATCH,
                    "Chasing game",
                ),
                (
                    ProjectType.ROBOTICS,
                    "Puppy",
                ),
                (
                    ProjectType.ROBOTICS,
                    "Simple human",
                ),
                (
                    ProjectType.ROBOTICS,
                    "Advanced human",
                ),
                (
                    ProjectType.APP_INVENTOR,
                    "Click counter",
                ),
                (
                    ProjectType.APP_INVENTOR,
                    "Color mixer",
                ),
                (
                    ProjectType.APP_INVENTOR,
                    "Piano",
                ),
            ],
        )

        add_session_logs(
            db,
            cdi,
            shared_mentors,
            [
                (
                    ProjectType.SCRATCH,
                    "Dino game",
                ),
                (
                    ProjectType.SCRATCH,
                    "Flower rain",
                ),
                (
                    ProjectType.SCRATCH,
                    "Drawing game",
                ),
                (
                    ProjectType.SCRATCH,
                    "Growing flower",
                ),
                (
                    ProjectType.ROBOTICS,
                    "Simple car",
                ),
                (
                    ProjectType.ROBOTICS,
                    "Advanced car",
                ),
                (
                    ProjectType.APP_INVENTOR,
                    "Drawing app",
                ),
                (
                    ProjectType.APP_INVENTOR,
                    "Translator app",
                ),
            ],
        )

        add_photo_submission(
            db,
            session_log=hillside_logs[0],
            mentor=abdallah,
            filenames=PHOTO_FILENAMES,
        )

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()
