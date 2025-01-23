class AdminManageCourses extends AdminPage {
    courseListItems = [];
    selectedCourse = null;
    
    constructor() {
        super("Manage courses");
    }

    async start() {
        this.getDomElements()
            .createFilters()
            .createModals()
            .activateButtons();
        await this.fetchCourses();
    }

    getDomElements() {
        this.courseListArea = document.querySelector(".listmenu-list");
        this.addCourseButton = document.querySelector(".listmenu-button.add");
        this.editCourseButton = document.querySelector(".listmenu-button.edit");
        this.filterArea = document.querySelector(".filter-container");
        return this;
    }
    
    createModals() {
        this.addEditCourse = new AddEditCourse();
        this.addEditCourse.setExitMethod(() => {
            this.closeModal(this.addEditCourse);
        });
        return this;
    }

    createFilters() {
        this.filters = new Filters(
            this.filterArea,
            this.filterCourses.bind(this)
        )
        return this;
    }

    filterCourses() {
        console.log(this.courseListItems[0]);
        const filteredCourses = this.filters.filterList(this.courseListItems);
        console.log(filteredCourses);
        this.courseListItems.forEach(name => {
            if (filteredCourses.includes(name)) {
                name.dom.classList.remove("undisplayed");
            } else {
                name.dom.classList.add("undisplayed");
            }
        })
    }
    
    activateButtons() {
        this.addCourseButton.addEventListener("click", () => {
            this.selectedCourse = null;
            this.openModal(this.addEditCourse);
        });
        this.editCourseButton.addEventListener("click", () => {
            if (this.selectedCourse) {
                this.openModal(this.addEditCourse);
            } else {
                this.notification.show("No course selected!", 2000);
            }
        });
        return this;
    }

    async fetchCourses() {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/admin/courselist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({"msg": "send courselist"})
        });
        
        const data = await response.json();
        if (response.ok) {
            console.log("courses:", data)
            this.notification.show("Course list loaded!", 2000, "good");
            this.generateCourseList(data);
        } else {
            console.error("Didn't get course data!");
            this.notification.show("Didn't get course data!", 2000, "bad");
        }
        return this;
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
            `<li class="listmenu-list-item">
                <label><input type="radio" name="course" value="${course.id}"> 
                    ${course.name}
                </label>
            </li>`.trim();
        course.dom = template.content.firstElementChild;
        course.radio = course.dom.firstElementChild.firstElementChild;
        course.radio.addEventListener("change", () => {
            this.selectedCourse = course;
        });
        return course
    }

    disableInterface() {
        for (let item of this.courseListItems) {
            item.radio.disabled = true;
            this.addCourseButton.disabled = true;
            this.editCourseButton.disabled = true;
            }
    }

    enableInterface() {
        for (let item of this.courseListItems) {
            item.radio.disabled = false;
        }
        this.addCourseButton.disabled = false;
        this.editCourseButton.disabled = false;
    }

    openModal(modal) {
        modal.setCourse(this.selectedCourse);
        this.disableInterface();
        this.header.setTitle(modal.course ? modal.title.edit : modal.title.add);
        modal.open();
    }

    closeModal(modal) {
        this.enableInterface();
        this.header.resetTitle();
        modal.close();
        this.fetchCourses(); // async
    }

}

new AdminManageCourses();


