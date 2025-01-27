from db import db
from datetime import datetime
from werkzeug.security import generate_password_hash
from models import (
    User,
    UserRole,
    RoleType, 
    CurriculumProject, 
    Skill, 
    Course, 
    LoginColor,
    LoginMascot,
    Student,
    StudentUser,
    Mentor, 
    Country,
    MentorCourse, 
    StudentCourse, 
    SessionLog, 
    )
from app import app
import random as r

def populate_database():

    lang_en = "en"
    lang_hu = "hu"
    lang_ua = "ua"
    country_hun = Country(
        code="hun", 
        name="Hungary",
        )
    country_svk = Country(
        code="svk", 
        name="Slovakia",
        )
    country_ukr = Country(
        code="ukr", 
        name="Ukraine",
        )
    db.session.add_all([country_hun, country_svk, country_ukr])
    db.session.flush()

    # data for mock mentors and admins
    user_data = [
        #testers
        {
            "email": "mekis.peter@example.com",
            "first_name": "Péter",
            "last_name": "Mekis",
            "preferred_language": lang_hu,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "vivien@example.com",
            "first_name": "Vivien",
            "last_name": "Mekis",
            "preferred_language": lang_hu,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "annamaria@example.com",
            "first_name": "Anna Maria",
            "last_name": "Markovich",
            "preferred_language": lang_hu,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },
        {
            "email": "diana@example.com",
            "first_name": "Diana",
            "last_name": "Filepova",
            "preferred_language": lang_hu,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_svk.id,
            "active": True
            },
        {
            "email": "bohdan@example.com",
            "first_name": "Bohdan",
            "last_name": "Toder",
            "preferred_language": lang_ua,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },
        {
            "email": "yevheny@example.com",
            "first_name": "Yevheny",
            "last_name": "Bortek",
            "preferred_language": lang_ua,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },
        {
            "email": "kata@example.com",
            "first_name": "Katalin",
            "last_name": "Gerhard",
            "preferred_language": lang_ua,
            "roles": [RoleType.ADMIN, RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },

        {
            "email": "ishtvan.dendeshi@example.com",
            "first_name": "Ishtvan",
            "last_name": "Dendeshi",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },
        {
            "email": "greskovics.eszter@example.com",
            "first_name": "Eszter",
            "last_name": "Greskovics",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "dominik.agi@example.com",
            "first_name": "Ági",
            "last_name": "Dominik",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "kovesdy.kati@example.com",
            "first_name": "Kati",
            "last_name": "Kövesdy",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "cynthia.ferkoova@example.com",
            "first_name": "Cynthia",
            "last_name": "Ferkóová",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_svk.id,
            "active": True
            },
        {
            "email": "alex.agocs@example.com",
            "first_name": "Alex",
            "last_name": "Agócs",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_svk.id,
            "active": True
            },
        {
            "email": "nadia.fontosh@example.com",
            "first_name": "Nadia",
            "last_name": "Fontosh",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": True
            },
        {
            "email": "patrik.ferko@example.com",
            "first_name": "Patrik",
            "last_name": "Ferkó",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_svk.id,
            "active": True
            },
        {
            "email": "virag.szelina@example.com",
            "first_name": "Szelina",
            "last_name": "Virág",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": True
            },
        {
            "email": "sukosd-kosa.misi@example.com",
            "first_name": "Misi",
            "last_name": "Sükösd-Kósa",
            "preferred_language": lang_en,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": False
            },
        {
            "email": "rezmuves.benjamin@example.com",
            "first_name": "Benjámin",
            "last_name": "Rézműves",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": False
            },
        {
            "email": "olah.norbi@example.com",
            "first_name": "Norbi",
            "last_name": "Oláh",
            "preferred_language": lang_hu,
            "roles": [RoleType.MENTOR],
            "country_id": country_hun.id,
            "active": False
            },
        {
            "email": "maksym.dzhum@example.com",
            "first_name": "Maksym",
            "last_name": "Dzhum",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": False
            },
        {
            "email": "oksana.kuzmanich@example.com",
            "first_name": "Oksana",
            "last_name": "Kuzmanich",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": False
            },
        {
            "email": "romanirota@example.com",
            "first_name": "Volodymyr",
            "last_name": "Bambula",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": False
            },
        {
            "email": "romanirota@example.com",
            "first_name": "Anzhelika",
            "last_name": "Panchen",
            "preferred_language": lang_ua,
            "roles": [RoleType.MENTOR],
            "country_id": country_ukr.id,
            "active": False
            },
        {
            "email": "gabor.daroczi@example.com",
            "roles": [RoleType.ADMIN],
            },
        {
            "email": "karasz.kata@example.com",
            "roles": [RoleType.ADMIN],
            },
        ]

    users = []
    mentors = []
    for record in user_data:
        if RoleType.ADMIN in record["roles"]:
            password = "adminpassword"
        else:
            password = "mentorpassword"

        # has user been created yet?
        user = User.query.filter(User.email == record["email"]).first()
        existing_roles = []
        if not user:
            # create new user
            user = User(
                email=record["email"],
                password_hash=generate_password_hash(password)
                )
            db.session.add(user)
            db.session.flush() # so that we have a user id
            users.append(user)
        else:
            existing_roles = [
                role.role.value 
                for role in UserRole.query.filter_by(
                    user_id=user.id
                    ).all()
                ]
            if "admin" in existing_roles + record["roles"]:
                raise ValueError("Admin users cannot be shared!")
        # assign mentor and admin roles, avoiding duplicates
        for role in record["roles"]:
            if role.value not in existing_roles:
                db.session.add(UserRole(user_id=user.id, role=role))
        db.session.flush()

        # create new mentor
        if RoleType.MENTOR in record["roles"]:
            mentor = Mentor(
                user_id=user.id, 
                first_name=record["first_name"], 
                last_name=record["last_name"],
                country_id=record["country_id"],
                preferred_language=record["preferred_language"],
                active=record["active"]
                )
            db.session.add(mentor)
            db.session.flush()
            mentors.append(mentor)

    print("Mentors:")
    for i, mentor in enumerate(mentors):
        print("   ", i, mentor.first_name, mentor.last_name)

    # Create skills
    skill0 = Skill(name="motion")
    skill1 = Skill(name="looks")
    skill2 = Skill(name="messages")
    skill3 = Skill(name="cloning")
    skill4 = Skill(name="variables")
    skill5 = Skill(name="lists")
    skill6 = Skill(name="math")
    skill7 = Skill(name="pen")
    skill8 = Skill(name="sound")
    skill9 = Skill(name="drawing")
    db.session.add_all([
        skill0, skill1, skill2, skill3, skill4,
        skill5, skill6, skill7, skill8, skill9
        ])
    db.session.flush()

    # Create curriculum projects
    curriculum_projects = [
        CurriculumProject(
            level="novice",
            age_group="11-14",
            size="full_project",
            skills=[skill0, skill1, skill4],
            title="dance"
            ),
        CurriculumProject(
            level="novice",
            age_group="11-14",
            size="full_project",
            skills=[skill0, skill1, skill4],
            title="dino"
            ),
        CurriculumProject(
            level="novice",
            age_group="8-10",
            size="mini_project",
            skills=[skill0, skill3, skill9],
            title="flowershower"
            ),
        CurriculumProject(
            level="novice",
            age_group="8-10",
            size="mini_project",
            skills=[skill0, skill3, skill9],
            title="balloon"
            ),
        CurriculumProject(
            level="novice",
            age_group="8-10",
            size="full_project",
            skills=[skill0, skill3, skill9],
            title="dressing"
            ),
        CurriculumProject(
            level="intermediate",
            age_group="11-14",
            size="full_project",
            skills=[skill1, skill2, skill4],
            title="simplequiz"
            ),
        CurriculumProject(
            level="advanced",
            age_group="11-14",
            size="full_project",
            skills=[skill2, skill4, skill5],
            title="quiz"
            ),
        CurriculumProject(
            level="master",
            age_group="11-14",
            size="full_project",
            skills=[skill2, skill4, skill5],
            title="romaniflag"
            ),
        ]
    db.session.add_all(curriculum_projects)
    db.session.flush()

        
    # Create courses
    courses = [
        # Bohdan
        Course(
            name="Uzhhorod 1", 
            description="Course in Elementary School 7 in Uzhhorod",
            country_id=country_ukr.id,
            active = True
            ),
        # Ishtvan
        Course(
            name="Uzhhorod 2", 
            description="Course in Elementary School 9 in Uzhhorod",
            country_id=country_ukr.id,
            active = True
            ),
        # Eszter, Ági
        Course(
            name="UMTK 1", 
            description="Wednesday course for Ukrainian refugees in Budapest",
            country_id=country_hun.id   ,
            active = False
            ),
        # Eszter, Ági
        Course(
            name="UMTK 2", 
            description="Friday course for Ukrainian refugees in Budapest",
            country_id=country_hun.id,
            active = False
            ),
        # Kati
        Course(
            name="Erdőkövesd 1", 
            description="Course for kids aged 8 to 10 in Erdőkövesd",
            country_id=country_hun.id,
            active = True
            ),
        # Kati
        Course(
            name="Erdőkövesd 2", 
            description="Course for kids aged 11 to 13 in Erdőkövesd",
            country_id=country_hun.id,
            active = True
            ),
        # Nadia, Oksana
        Course(
            name="Turya Pasika 1", 
            description="Course in the Turya Pasika elementary school",
            country_id=country_ukr.id,
            active = True
            ),
        # Nadia
        Course(
            name="Turya Pasika 2", 
            description="Course in the Turya Pasika settlement",
            country_id=country_ukr.id,
            active = True
            ),
        # -
        Course(
            name="Zolotonosha", 
            description="Course in the Romani Rom center",
            country_id=country_ukr.id,
            active = True
            ),
        # Maksym
        Course(
            name="Odesa", 
            description="Course in the Odesa Roma community center",
            country_id=country_ukr.id,
            active = True
            ),
        # Cynthia, Alex
        Course(
            name="Baraca", 
            description="Course in Baraca",
            country_id=country_svk.id,
            active = True
            ),
        # Patrik
        Course(
            name="Uzapanyit", 
            description="Course in Uzapanyit",
            country_id=country_svk.id,
            active = True
            ),
        # Misi
        Course(
            name="Bátonyterenye", 
            description="Course in Bátonyterenye",
            country_id=country_hun.id,
            active = True
            ),
        # Szelina
        Course(
            name="Zugliget", 
            description="Course in Zugliget refugee shelter",
            country_id=country_hun.id,
            active = True
            ),
        # -
        Course(
            name="Tornalja", 
            description="Course in the Tornalja elementary school",
            country_id=country_hun.id,
            active = True
            ),
        ]
    db.session.add_all(courses)
    db.session.flush()

    print("Courses:")
    for i, course in enumerate(courses):
        print("   ", i, course.name)

    #assign courses to mentors (many-to-many)
    mentor_course_pairs = [
        (1, 1), (2, 2), (3, 3), (3, 4), (4, 3), 
        (4, 4), (5, 5), (5, 6), (6, 11), (7, 11), 
        (8, 7), (8, 8), (9, 12), (10, 14), (11, 13), 
        (14, 10), (15, 7)
        ]
    mentor_courses = [
    MentorCourse(
            mentor_id=mentor_id, 
            course_id=course_id
           )
        for mentor_id, course_id in mentor_course_pairs
        ]   
    db.session.add_all(mentor_courses)
    db.session.flush()

    # for student login:
    color_names = [
        "red", "blue", "yellow", "green", 
        "orange", "purple", "pink", 
        "brown", "cyan", "lime", "gray"
        ]
    mascot_names = [
        "bear", "beetle", "butterfly", "cat", "dog",
        "elephant", "giraffe", "hedgehog", "pony", "owl",
        "rabbit"
        ]
    colors = [
        LoginColor(name=color_name) for color_name in color_names
        ] 
    mascots = [
        LoginMascot(name=mascot_name) for mascot_name in mascot_names
        ]
    db.session.add_all(colors)
    db.session.add_all(mascots)
    db.session.flush()

    # Create students
    hungarian_students = [
        # 5 Erdőkövesd 1: 1-6
        {
            "first_name": "Ágnes",
            "last_name": "Antal",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Balázs",
            "last_name": "Barta",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Csilla",
            "last_name": "Csáki",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Dávid",
            "last_name": "Dombai",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Eszter",
            "last_name": "Erős",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Ferenc",
            "last_name": "Farkas",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 6 Erdőkövesd 2: 7-11
        {
            "first_name": "Gábor",
            "last_name": "Gulyás",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Hanna",
            "last_name": "Harsányi",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "István",
            "last_name": "Iván",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Júlia",
            "last_name": "Juhász",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Katalin",
            "last_name": "Kiss",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 13 Bátonyterenye: 12-17
        {
            "first_name": "László",
            "last_name": "Lévai",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Mónika",
            "last_name": "Módos",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Norbert",
            "last_name": "Nagy",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Orsolya",
            "last_name": "Oláh",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Péter",
            "last_name": "Papp",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Rózsa",
            "last_name": "Rácz",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 14 Zugliget: 18-21
        {
            "first_name": "Szabolcs",
            "last_name": "Szalai",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Tímea",
            "last_name": "Takács",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Viktor",
            "last_name": "Varga",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Zoltán",
            "last_name": "Zsigmond",
            "country_id": country_hun.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }
        ]

    slovakian_students = [
        # 11 Baraca: 22-27
        {
            "first_name": "Alena",
            "last_name": "Adamčíková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Branislav",
            "last_name": "Bartoš",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Cecília",
            "last_name": "Cibulová",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Daniel",
            "last_name": "Doležal",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Eva",
            "last_name": "Endresová",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Filip",
            "last_name": "Fedor",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 12 Uzapanyit: 28-34
            {
            "first_name": "Gabriela",
            "last_name": "Gašparíková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Henrich",
            "last_name": "Horváth",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Ivana",
            "last_name": "Iváneková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Jozef",
            "last_name": "Jurčák",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Kristína",
            "last_name": "Kováčová",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Lukáš",
            "last_name": "Lužina",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Martina",
            "last_name": "Michalíková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 15 Tornalja: 35-42
        {
            "first_name": "Nina",
            "last_name": "Nováková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Ondrej",
            "last_name": "Oravec",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Petra",
            "last_name": "Pavlíková",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Renáta",
            "last_name": "Rybárová",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Samuel",
            "last_name": "Sabol",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Tomáš",
            "last_name": "Tóth",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Vladimír",
            "last_name": "Veselý",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Zuzana",
            "last_name": "Zemanová",
            "country_id": country_svk.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }
        ]

    ukrainian_students = [
        # 1 Uzhhorod 1: 43-46
        {
            "first_name": "Anastasiya",
            "last_name": "Antonovych",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Bohdan",
            "last_name": "Babiak",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Viktoriya",
            "last_name": "Vasylchenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Dmytro",
            "last_name": "Dudnyk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 2 Uzhhorod 2:
        {
            "first_name": "Yevheniia",
            "last_name": "Yevtushenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }, 
        {
            "first_name": "Fedir",
            "last_name": "Filatov",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Hanna",
            "last_name": "Holub",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 3 UMTK 1: 50-52
        {
            "first_name": "Hryhoriy",
            "last_name": "Hrytsenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Inna",
            "last_name": "Ivanyuk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Jakiv",
            "last_name": "Jaremchuk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 4 UMTK 2: 53-56
        {
            "first_name": "Kateryna",
            "last_name": "Kovalchuk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Larysa",
            "last_name": "Lytvynenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Mykhailo",
            "last_name": "Melnyk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Natalia",
            "last_name": "Nazaruk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 7 Turya Pasika 1: 57-60
        {
            "first_name": "Oleh",
            "last_name": "Onyshchenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Polina",
            "last_name": "Pavlenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Ruslan",
            "last_name": "Rudenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Serhiy",
            "last_name": "Shevchenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        # 10 Odesa: 61-64 
        {
            "first_name": "Tetiana",
            "last_name": "Tymoshchuk",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Volodymyr",
            "last_name": "Vasylchenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "M",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Yuliya",
            "last_name": "Yurchenko",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            },
        {
            "first_name": "Zoryana",
            "last_name": "Zvarych",
            "country_id": country_ukr.id,
            "birth_year": r.randint(2009, 2016),
            "gender": "F",
            "mascot_id": 2,
            "color_id": 2,
            "active": True
            }
        ]
    students = []
    student_data = hungarian_students + slovakian_students + ukrainian_students
    for record in student_data:
        student_user = StudentUser(
            color_id = record["color_id"],
            mascot_id = record["mascot_id"]
            )
        db.session.add(student_user)
        db.session.flush() # so that we have an id
        student = Student(
            student_user_id=student_user.id,
            first_name=record["first_name"],
            last_name=record["last_name"],
            country_id=record["country_id"],
            birth_year=record["birth_year"],
            gender=record["gender"],
            active=record["active"]
            )
        students.append(student)
    db.session.add_all(students)
    db.session.flush()

    print("Students:")
    for i, student in enumerate(students):
        print("   ", i, student.first_name, student.last_name)

    # Assign students to courses
    course_student_pairs = [
        (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), 
        (5, 6), (6, 7), (6, 8), (6, 9), (6, 10), 
        (6, 11), (13, 12), (13, 13), (13, 14), (13, 15), 
        (13, 16), (13, 17), (14, 18), (14, 19), (14, 20), 
        (14, 21), (11, 22), (11, 23), (11, 24), (11, 25),     
        (11, 26), (11, 27), (12, 28), (12, 29), (12, 30),     
        (12, 31), (12, 32), (12, 33), (12, 34), (15, 35),     
        (15, 36), (15, 37), (15, 38), (15, 39), (15, 40),     
        (15, 41), (15, 42), (1, 43), (1, 44), (1, 45),     
        (1, 46), (2, 47), (2, 48), (2, 49), (3, 50),     
        (3, 51), (3, 52), (4, 53), (4, 54), (4, 55),     
        (4, 56), (7, 57), (7, 58), (7, 59), (7, 60),     
        (10, 61), (10, 62), (10, 63), (10, 64)     
        ]

    student_courses = [
        StudentCourse(
            student_id=s_id,
            course_id=c_id
            )
        for c_id, s_id in course_student_pairs
        ]
    db.session.add_all(student_courses)
    db.session.flush()

    # Create session logs with curriculum projects
    def create_session_log(mentor, course, project, date, students):
        return SessionLog(
            mentor_id=mentor.id,
            course_id=course.id,
            date=date,
            project_id=project.id,
            project_title=project.title,
            size=project.size,
            level=project.level,
            students=students,
            skills=project.skills,
            issues="no issues"
            )

    session_logs = [
        # Bohdan 1
        create_session_log(
            mentor=mentors[0],
            course=courses[0],
            project=curriculum_projects[1],
            date=datetime(2024, 9, 25),
            students=students[42:45]
            ),
        # Bohdan 2
        create_session_log(
            mentor=mentors[0],
            course=courses[0],
            project=curriculum_projects[3],
            date=datetime(2024, 10, 1),
            students=students[43:46]
            ),
        # Ishtvan 1
        create_session_log(
            mentor=mentors[1],
            course=courses[1],
            project=curriculum_projects[4],
            date=datetime(2024, 9, 16),
            students=students[46:49]
            ),
        # Ishtvan 2
        create_session_log(
            mentor=mentors[1],
            course=courses[1],
            project=curriculum_projects[1],
            date=datetime(2024, 9, 23),
            students=students[47:49]
            ),
        # Eszter 1
        create_session_log(
            mentor=mentors[2],
            course=courses[2],
            project=curriculum_projects[3],
            date=datetime(2024, 9, 20),
            students=students[49:52]
            ),
        # Eszter 2
        create_session_log(
            mentor=mentors[2],
            course=courses[2],
            project=curriculum_projects[1],
            date=datetime(2024, 9, 27),
            students=students[49:51]
            )
        ]
    db.session.add_all(session_logs)
    db.session.flush()
        

if __name__ == '__main__':
    with app.app_context():
        try: 
            populate_database()
            db.session.commit()
            print("Database populated successfully with mock data.")
        except Exception as e:
            print(e)
            db.session.rollback()
