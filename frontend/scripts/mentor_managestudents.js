// Contains a lot of repetitive code from AdminManageStudents
// TODO: refactor with the ManagePage class
// TODO: uses admin route for adding student; to be solved with refactoring

class MentorManageStudents extends MentorPage {
    studentListItems = [];
    selectedStudent = null;
    constructor() {
        super("Manage students");
        this.languageMenu = new LanguageMenu((lang) => {
            this.setLanguage(lang);
        });
    }

    async start() {
        this.getDomElements()
            .setLanguage(this.preferredLanguage)
            .createModals()
            .activateButtons();
        await this.fetchStudents();
    }

    getDomElements() {
        super.getDomElements();
        this.studentListArea = document.querySelector(".listmenu-list");
        this.addStudentButton = document.querySelector(".listmenu-button.add");
        this.editStudentButton = document.querySelector(".listmenu-button.edit");
        this.filterArea = document.querySelector(".filter-container");
        this.textFields = document.querySelectorAll(".language-text")
        return this;
    }
    
    createModals() {
        this.addEditStudent = new MentorAddEditStudent();
        this.addEditStudent.setExitMethod(() => {
            this.closeModal(this.addEditStudent);
        });
        return this;
    }

    activateButtons() {
        this.addStudentButton.addEventListener("click", () => {
            this.selectedStudent = null;
            this.openModal(this.addEditStudent);
        });
        this.editStudentButton.addEventListener("click", () => {
            if (this.selectedStudent) {
                this.openModal(this.addEditStudent);
            } else {
                this.notification.show("No student selected!", 2000);
            }
        });
        return this;
    }

    async fetchStudents() {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/mentor/studentlist`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({"msg": "send studentlist"})
        });
        
        const data = await response.json();
        if (response.ok) {
            this.notification.show("Student list loaded!", 2000, "good");
            this.generateStudentList(data);
        } else {
            console.error("Didn't get student data!");
            this.notification.show("Didn't get student data!", 2000, "bad");
        }
        return this;
    }

    generateStudentList(students) {
        this.removeChildNodes(this.studentListArea);
        this.studentListItems = [];
        for (let student of students) {
            const listItem = this.createStudentListItem(student);
            this.studentListArea.appendChild(listItem.dom);
            this.studentListItems.push(listItem);
        }
    }

    removeChildNodes(dom) {
        while (dom.firstChild) {
            dom.removeChild(dom.lastChild);
        }
    }

    createStudentListItem(student) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<li class="listmenu-list-item">
                <label><input type="radio" name="student" value="${student.id}"> 
                    ${student.first_name}, ${student.last_name}
                </label>
            </li>`.trim();
        student.dom = template.content.firstElementChild;
        student.radio = student.dom.firstElementChild.firstElementChild;
        student.radio.addEventListener("change", () => {
            this.selectedStudent = student;
        });
        return student
    }

    disableInterface() {
        for (let item of this.studentListItems) {
            item.radio.disabled = true;
            this.addStudentButton.disabled = true;
            this.editStudentButton.disabled = true;
            }
    }

    enableInterface() {
        for (let item of this.studentListItems) {
            item.radio.disabled = false;
        }
        this.addStudentButton.disabled = false;
        this.editStudentButton.disabled = false;
    }

    openModal(modal) {
        modal.setStudent(this.selectedStudent);
        this.disableInterface();
        this.header.setTitle(modal.student ? modal.title.edit : modal.title.add);
        modal.open();
    }

    closeModal(modal) {
        this.enableInterface();
        this.header.resetTitle();
        modal.close();
        this.fetchStudents(); // async
    }

    setLanguage(language) {
        super.setLanguage(language);
        this.language = language
        this.languageMenu.adjustMenu(language)
        this.header.setTitle(mentorStudentTitle[language]);
        this.textFields.forEach((field, i) => {
            field.innerHTML = mentorStudentPageTexts[language][i];
        });
        return this;
    }
}

new MentorManageStudents();


