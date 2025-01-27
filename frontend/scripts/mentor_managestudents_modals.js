// TODO: better organize form handling
//       1. text input fields should be in a list, 
//          and handled by name
//       2. Form (in base.js) should be updated to handle
//          checkbox groups as multiselect lists,
//          so that Form can be used here

class MentorAddEditStudent extends Modal {
    title = {
        add: "Add student", 
        edit: "Edit student"
    };
    student = null;
    courseListItems = [];
    countries = [];

    constructor() {
        const overlay = document.querySelector(".overlay.manage-student")
        super(overlay);
        this.getDomElements();
        this.fetchCourses(); // async
    }

    getDomElements() {
        this.cancelButton = this.overlay
            .querySelector("button.cancel");
        this.cancelButton.addEventListener("click", (e) => {
            e.preventDefault();
            this.exit();
        })
        const formArea = this.overlay
            .querySelector(".manage-student-form");
        this.courseListArea = formArea
            .querySelector(".course-list");
        this.form = {
            firstNameInput: formArea
                .querySelector("input[name='first_name']"),
            lastNameInput: formArea
                .querySelector("input[name='last_name']"),
            countryInput: formArea
                .querySelector("select[name='country']"),
            birth_yearInput: formArea
                .querySelector("input[name='birth_year']"),
            genderInput: formArea
                .querySelector("select[name='gender']"),
            activeInput: formArea
                .querySelector("input[name='active']"),
        };
        formArea.addEventListener("submit", (event) => {
            event.preventDefault();
            this.handleSubmission(event);
        });
    }

    async fetchCourses() {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/mentor/courselist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({"msg": "send courselist"})
        });
        const data = await response.json();
        if (response.ok) {
            this.generateCourseList(data);
        } else {
            console.error("Didn't get course data!");
        }
    }

    generateCourseList(courses) {
        this.removeChildNodes(this.courseListArea);
        this.courseListItems = [];
        for (let course of courses) {
            const listItem = this.createCourseListItem(course);
            this.courseListArea.appendChild(listItem.dom);
            this.courseListItems.push(listItem);
        }
    }

    removeChildNodes(dom) {
        while (dom.firstChild) {
            dom.removeChild(dom.lastChild);
        }
    }

    createCourseListItem(course) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<li class="course-list-item">
                <label><input type="checkbox" name="course" value="${course.id}"> 
                    ${course.name}
                </label>
            </li>`.trim();
        const listItemDom = template.content.firstElementChild;
        const checkBox = listItemDom.firstElementChild.firstElementChild;
        checkBox.addEventListener("change", () => {
            console.log(course.id)
        });
        return {
            course: course,
            dom: listItemDom,
            checkBox: checkBox,
        }
    }

    clearData() {
        this.form.firstNameInput.value = "";
        this.form.lastNameInput.value = "";
        this.form.countryInput.value = "";
        this.form.birth_yearInput.value = "";
        this.form.genderInput.value = "";
        this.courseListItems.forEach((item) => {
            item.checkBox.checked = false;
        });
    }

    fillData() {
        console.log(this.student)
        this.form.firstNameInput.value = this.student.first_name;
        this.form.lastNameInput.value = this.student.last_name;
        this.form.countryInput.value = this.student.country_id;
        this.form.birth_yearInput.value = this.student.birth_year;
        this.form.genderInput.value = this.student.gender;
        this.courseListItems.forEach((item) => {
            if (this.student.courses.includes(item.course.id)) {
                item.checkBox.checked = true;
                console.log("id:", item.course.id);
            } else {
                item.checkBox.checked = false;
            }
        });
    }

    async handleSubmission() {
        const first_name = this.form.firstNameInput.value;
        const last_name = this.form.lastNameInput.value;
        const country_id = this.form.countryInput.value;
        const birth_year = this.form.birth_yearInput.value;
        const gender = this.form.genderInput.value;
        const active = this.form.activeInput.checked;
        console.log(active);
        const course_ids = this.getSelectedCourseIds();
        let student_id;
        if (this.student) {
            student_id = this.student.id;
        } else {
            student_id = null;
        }
        if (!first_name || !last_name || !country || !birth_year){
            console.log("Empty fields.");
            this.notification.bad("Please fill all fields.");
        } else if (!country_id) {
            console.log("Country not found.");
            this.notification.bad("Wrong country name!");
        } else {
            const token = localStorage.getItem("token");
            if (token) {
                const response = await fetch(`${window.API_BASE_URL}/api/shared/manage_student`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({
                        student_id,
                        first_name,
                        last_name,
                        country_id,
                        birth_year,
                        gender,
                        active,
                        course_ids
                    })
                });
                const data = await response.json();
                if (response.ok) {
                    // save token
                    console.log(data.msg)
                    this.notification.good("Student added successfully!");
                    this.timer.delay(() => {this.exit();}, 500);
                } else {
                    console.log("There was an error: " + data.msg);
                    this.notification.bad(data.msg,);
                }
            } else {
                this.config.redirect("index");
            }
        }
    }

    getSelectedCourseIds() {
        return this.courseListItems
            .filter(item => item.checkBox.checked)
            .map(item => item.course.id);
    }

    setStudent(student) {
        this.student = student;
    }

    open() {
        super.open();
        if (this.student) {
            this.fillData();
        } else {
            this.clearData();
        }
    }

}
