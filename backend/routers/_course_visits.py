from models import CourseVisitReport
from schemas.course_visits import (
    CourseVisitActionOut,
    CourseVisitMentorOut,
    CourseVisitReportOut,
    CourseVisitStudentOut,
)


def course_visit_report_to_out(
    report: CourseVisitReport,
) -> CourseVisitReportOut:
    return CourseVisitReportOut(
        id=report.id,
        submitted_by_admin_profile_id=(
            report.submitted_by_admin_profile_id
        ),
        course_id=report.course_id,
        date=report.date,
        session_status=report.session_status,
        teaching_took_place=report.teaching_took_place,
        session_followed_plan=report.session_followed_plan,
        learner_engagement=report.learner_engagement,
        equipment_adequate=report.equipment_adequate,
        environment_status=report.environment_status,
        what_happened=report.what_happened,
        main_strength=report.main_strength,
        main_problem=report.main_problem,
        support_provided=report.support_provided,
        course_health_rating=report.course_health_rating,
        safeguarding_concern=report.safeguarding_concern,
        safeguarding_note=report.safeguarding_note,
        mentors=[
            CourseVisitMentorOut(
                mentor_id=mentor.mentor_profile_id,
                role=mentor.role,
                performance_rating=mentor.performance_rating,
            )
            for mentor in sorted(
                report.mentors,
                key=lambda item: item.mentor_profile_id,
            )
        ],
        students=[
            CourseVisitStudentOut(
                student_id=student.student_id,
                interviewed=student.interviewed,
                enjoyment=student.enjoyment,
                learning=student.learning,
                feels_safe=student.feels_safe,
                note=student.note,
            )
            for student in sorted(
                report.students,
                key=lambda item: item.student_id,
            )
        ],
        actions=[
            CourseVisitActionOut(
                id=action.id,
                category=action.category,
                description=action.description,
                responsible_person=action.responsible_person,
                target_date=action.target_date,
                completed=action.completed,
                completed_at=action.completed_at,
            )
            for action in sorted(
                report.actions,
                key=lambda item: item.id,
            )
        ],
        created_at=report.created_at,
        updated_at=report.updated_at,
    )
