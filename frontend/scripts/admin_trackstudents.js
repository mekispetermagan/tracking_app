class TrackStudents extends AdminPage {
    students = [];
    courses = [];
    selectedStudent = null;
    constructor() {
        super("Track students");
        this.displayProgress = new DisplayProgress();
        this.displayProgress.setExitMethod(() => {
            this.closeModal(this.displayProgress);
        });
    }
    
    start() {
        this.getDomElements()
            .activateDomElements();
        this.fetchStudents(); // async
        this.fetchCourses(); // async

    }

    getDomElements() {
        this.studentLabelList = document
            .querySelector(".student.label-list");
        this.courseLabelList = document
            .querySelector(".course.label-list");
        this.courseArea = document
            .querySelector(".course.label-list-outer");
        this.allStudentsButton = document
            .querySelector(".toggle-button.all");
        this.byCourseButton = document
            .querySelector(".toggle-button.by-course");
        this.checkProgressButton = document
            .querySelector(".track-student-button.check-progress");
        return this;
    }

    activateDomElements() {
        this.allStudentsButton.addEventListener("click", () => {
            this.allStudentsButton.classList.remove("off");
            this.byCourseButton.classList.add("off");
            this.courseArea.classList.add("hidden");
            this.filterByCourse(null);
        });
        this.byCourseButton.addEventListener("click", () => {
            this.allStudentsButton.classList.add("off");
            this.byCourseButton.classList.remove("off");
            this.courseArea.classList.remove("hidden");
        });
        this.checkProgressButton.addEventListener("click", () => {
            if (this.selectedStudent) {
                this.openModal(this.displayProgress);
                } else {
            this.notification.show(
                    "Choose a student!",
                    1000,
                    "bad"
                );
            }

        });
    }

    async fetchStudents() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/admin/studentlist`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send students"})
            });

            const data = await response.json();
            if (response.ok) {
                if (data.length == 0) {
                    this.studentLabelList.insertAdjacentHTML(
                        "beforeend",
                        "There are no students in the database."
                    );
                } else {
                    for (let student of data) {
                        const studentItem = this.generateStudentLabel(student);
                        this.studentLabelList.appendChild(studentItem.dom);
                        this.students.push(studentItem);
                    }
                }
            } else {
                console.error("Students couldn't be fetched.", data.msg);
                this.notification.show(data.msg, 1000, "bad");
            }
        } else {
            console.error("No token found.");
            this.notification.show("Logged out.", 1000, "bad");
        }
    }

    async fetchCourses() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/admin/courselist`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send courses"})
            });

            const data = await response.json();
            if (response.ok) {
                if (data.length == 0) {
                    this.courseLabelList.insertAdjacentHTML(
                        "beforeend",
                        "There are no courses in the database."
                    );
                } else {
                    for (let course of data) {
                        const courseItem = this.generateCourseLabel(course);
                        this.courseLabelList.appendChild(courseItem.dom);
                        this.courses.push(courseItem);
                    }
                }
            } else {
                console.error("Students couldn't be fetched.", data.msg);
                this.notification.show(data.msg, 1000, "bad");
            }
        } else {
            console.error("No token found.");
            this.notification.show("Logged out.", 1000, "bad");
        }
    }

    generateStudentLabel(student) {
        const template = document.createElement("template");
        const id = student.id;
        const first_name = student.first_name
        const last_name = student.last_name
        const courses = student.courses
        template.innerHTML = 
                `<label class="track-label student-label">
                    <input 
                        type="radio"
                        name="student"
                        id="student${id}" 
                        value="${id}"> 
                    ${last_name},&nbsp;${first_name}
                </label>`.trim();
        const dom = template.content.firstElementChild;
        const radio = dom.firstElementChild;
        radio.addEventListener("change", () => {
            this.selectedStudent = {id, first_name, last_name};
        })
        return {
            id,
            first_name,
            last_name, 
            courses,
            dom, 
            radio
        };
    }

    generateCourseLabel(course) {
        const template = document.createElement("template");
        const id = course.id;
        const name = course.name
        const description = course.description
        template.innerHTML = 
                `<label class="track-label course-label">
                    <input 
                        type="radio"
                        name="course"
                        id="course${id}" 
                        value="${id}"> 
                    ${name}
                </label>`.trim();
        const dom = template.content.firstElementChild;
        const radio = dom.firstElementChild;
        radio.addEventListener("change", () => {
            this.filterByCourse(course.id);
        });
        return {
            id,
            name,
            description, 
            dom, 
            radio
        };
    }

    filterByCourse(course) {
        this.selectedStudent = null;
        this.students.forEach( (student) => {
            if (!course || student.courses.includes(course)) {
                student.dom.classList.remove("not-displayed");
            } else {
                student.dom.classList.add("not-displayed");
            }
            student.radio.checked = false;
        });
    }

    disableInterface() {
        this.allStudentsButton.disabled = true;
        this.byCourseButton.disabled = true;
        this.checkProgressButton.disabled = true;
    }

    enableInterface() {
        this.allStudentsButton.disabled = false;
        this.byCourseButton.disabled = false;
        this.checkProgressButton.disabled = false;
    }

    openModal(modal) {
        this.disableInterface();
        this.header.setTitle(modal.title);
        modal.setStudent(this.selectedStudent);
        modal.open();
    }

    closeModal(modal) {
        this.enableInterface();
        this.header.resetTitle();
        modal.close();
    }


}

new TrackStudents();