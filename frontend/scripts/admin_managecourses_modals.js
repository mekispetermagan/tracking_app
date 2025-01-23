class AddEditCourse extends Modal {
    title = {
        add: "Add course", 
        edit: "Edit course"
    };
    course = null;
    mentorListItems = [];

    constructor() {
        const overlay = document.querySelector(".overlay.manage-course")
        super(overlay);
        this.getDomElements();
        this.fetchMentors(); // async
    }

    getDomElements() {
        this.cancelButton = this.overlay
            .querySelector("button.cancel");
        this.cancelButton.addEventListener("click", (e) => {
            e.preventDefault();
            this.exit();
        })
        const formArea = this.overlay
            .querySelector(".manage-course-form");
        this.mentorListArea = formArea
            .querySelector(".mentor-list");
        this.form = {
            name: formArea.querySelector(".name-input"),
            description: formArea.querySelector(".description-input"),
            countryId: formArea.querySelector(".country_id"),
        };
        formArea.addEventListener("submit", (event) => {
            event.preventDefault();
            this.handleSubmission(event);
        });
    }

    async fetchMentors() {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/admin/mentorlist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({"msg": "send mentorlist"})
        });
        
        const data = await response.json();
        if (response.ok) {
            this.generateMentorList(data);
        } else {
            console.error("Didn't get mentor data!");
        }
    }

    generateMentorList(mentors) {
        this.removeChildNodes(this.mentorListArea);
        this.mentorListItems = [];
        for (let mentor of mentors) {
            const listItem = this.createMentorListItem(mentor);
            this.mentorListArea.appendChild(listItem.dom);
            this.mentorListItems.push(listItem);
        }
    }

    removeChildNodes(dom) {
        while (dom.firstChild) {
            dom.removeChild(dom.lastChild);
        }
    }

    createMentorListItem(mentor) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<li class="mentor-list-item">
                <label><input type="checkbox" name="mentor" value="${mentor.id}"> 
                    ${mentor.first_name}, ${mentor.last_name}
                </label>
            </li>`.trim();
        const listItemDom = template.content.firstElementChild;
        const checkBox = listItemDom.firstElementChild.firstElementChild;
        checkBox.addEventListener("change", () => {
            console.log(mentor.id)
        });
        return {
            mentor: mentor,
            dom: listItemDom,
            checkBox: checkBox,
        }
    }

    clearData() {
        this.form.name.value = "";
        this.form.description.value = "";
        this.form.countryId.value = "";
        this.mentorListItems.forEach((item) => {
            item.checkBox.checked = false;
        });
    }

    fillData() {
        console.log(this.course)
        this.form.name.value = this.course.name;
        this.form.description.value = this.course.description;
        this.form.countryId.value = this.course.country_id;
        this.mentorListItems.forEach((item) => {
            if (this.course.mentors.includes(item.mentor.id)) {
                item.checkBox.checked = true;
                console.log("id:", item.mentor.id);
            } else {
                item.checkBox.checked = false;
            }
        });
    }

    async handleSubmission() {
        const name = this.form.name.value;
        const description = this.form.description.value;
        const country_id = this.form.countryId.value;
        const mentorIds = this.getSelectedMentorIds();
        console.log(mentorIds);
        let mode, course_id;
        if (this.course) {
            mode = "edit";
            course_id = this.course.id;
        } else {
            mode = "add";
            course_id = null;
        }
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/admin/manage_course`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    mode,
                    course_id,
                    name,
                    description,
                    country_id,
                    mentorIds
                })
            });
            const data = await response.json();
            if (response.ok) {
                // save token
                console.log(data.msg)
                this.notification.show("Course added successfully!", 2000, "good");
                this.timer.delay(() => {this.exit();}, 500);
            } else {
                console.log("There was an error: " + data.msg);
                this.notification.show(data.msg, 2000, "bad");
            }
        } else {
            this.config.redirect("index");
        }
    }

    getSelectedMentorIds() {
        return this.mentorListItems
            .filter(item => item.checkBox.checked)
            .map(item => item.mentor.id);
    }

    setCourse(course) {
        this.course = course;
    }

    open() {
        super.open();
        if (this.course) {
            this.fillData();
        } else {
            this.clearData();
        }
    }

}
