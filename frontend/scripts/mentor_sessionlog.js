class MentorSessionLog extends MentorPage{
    mentor = null;
    courses = [];
    students = [];
    projects = [];
    levels = [];
    skills = [];
    customProject = false;
    constructor() {
        super("Session log");
    }

    start() {
        this.getDomElements()
            .clearContainers()
            .activateElements()
            .setLanguage(this.preferredLanguage)
        this.fetchMentorData(); // async
        this.fetchCourses(); // async
        this.fetchCurriculum(); // async
    }

    getDomElements() {
        super.getDomElements();
        this.sessionLogForm = document
            .querySelector("#sessionlog-form");
        this.toggle = document
            .querySelector("#project-type-toggle");
        this.curriculumLabel = document
            .querySelector("#toggle-label-curriculum");
        this.customLabel = document
            .querySelector("#toggle-label-custom");
        this.curriculumSection = document
            .querySelector(".sessionlog-section.curriculum");
        this.customSection = document
            .querySelector(".sessionlog-section.custom");
        this.textFields = [...document
            .querySelectorAll(".sessionlog-text")];
        this.mentorContainer = document
            .querySelector(".sessionlog.mentor-container");
        this.coursesContainer = document
            .querySelector(".sessionlog.course-container");
        this.curriculumProjectContainer = document
            .querySelector(".sessionlog.curriculum-project-container");
        this.levelsContainer = document
            .querySelector(".sessionlog.custom-project-levels");
        this.skillsContainer = document
            .querySelector(".sessionlog.custom-project-skills");
        this.studentsContainer = document
            .querySelector(".sessionlog.student-container");
        this.sizeOptions = [...document
            .querySelectorAll(".sessionlog-size")];
        this.cancelButton = document
            .querySelector("button.cancel");
        this.submitButton = document
            .querySelector("button.submit");
        this.customProjectTitleInput = document
            .querySelector("#custom-project-title"); 
        this.issuesInput = document
            .querySelector("#issues"); 
        this.dateInput = document
            .querySelector("#session-date");
        this.dateInput.valueAsDate = new Date(); // set date to today
        this.romaInput = document.querySelector("input[name='roma']");
        return this;
    }

    removeChildNodes(dom) {
        while (dom.firstChild) {
            dom.removeChild(dom.lastChild);
        }
    }

    clearContainers() {
        this.removeChildNodes(this.mentorContainer);
        this.removeChildNodes(this.coursesContainer);
        this.removeChildNodes(this.studentsContainer);
        this.removeChildNodes(this.skillsContainer);
        this.courses = [];
        this.students = [];
        return this;
    }

    activateElements() {
        this.toggle.addEventListener("change", () => {
            this.toggleCustomCurriculum();
        });
        this.toggle.checked = false;
        this.toggleCustomCurriculum();
        this.cancelButton.addEventListener("click", (e) => {
            e.preventDefault();
            this.config.redirect("mentor")
        })
        this.sessionLogForm.addEventListener("submit", (e) => {
            e.preventDefault();
            this.submitLog();
        });
        // this.submitButton.addEventListener("click", (e) => {
        //     e.preventDefault();
        //     this.submitLog();
        // });
        return this;
    }

    toggleCustomCurriculum() {
        const curriculumRequiredFields = [...
            document.querySelectorAll(".curriculum-required-field")
        ];
        const customRequiredFields = [...
            document.querySelectorAll(".custom-required-field")
        ];
        // checked: custom fields required
        customRequiredFields.forEach((field) => {
            field.required = this.toggle.checked;
        });
        // unchecked: curriculum fields required
        curriculumRequiredFields.forEach((field) => {
            field.required = !this.toggle.checked;}
        );
        if (this.toggle.checked) {
            // checked: custom project
            this.customSection.style.display = "block"; // custom section shown
            this.curriculumSection.style.display = "none"; // curriculum section hidden
            this.curriculumLabel.classList.remove("active"); // left label pale
            this.customLabel.classList.add("active"); // right label bright
        } else {
            // unchecked: curriculum project
            this.customSection.style.display = "none"; // custom section hidden
            this.curriculumSection.style.display = "block"; // curriculum section shown
            this.curriculumLabel.classList.add("active"); // left label bright
            this.customLabel.classList.remove("active"); // right label pale
        }
    }
    
    setLanguage(language) {
        super.setLanguage(language);
        this.language = language
        this.languageMenu.adjustMenu(language)
        this.header.setTitle(sessionLogText[language].title);
        this.textFields.forEach((field, i) => {
            field.innerHTML = fieldTexts[language][i];
        });
        this.generateLevelLabels();
        this.generateSkillLabels();
    }

    async fetchMentorData() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/mentor/get_mentor_data`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send courses"})
            });

            const data = await response.json();
            if (response.ok) {
                this.mentor = data;
                this.mentorContainer.innerHTML = `${data.last_name}, ${data.first_name}`;

            } else {
                console.error("Mentor data couldn't be fetched.", data.msg);
                this.notification.bad(data.msg);
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
        }
            
    }

    async fetchCourses() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/mentor/get_courses`, {
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
                    this.coursesContainer.insertAdjacentHTML(
                        "beforeend",
                        noCourseMessage[this.language]
                    );
                } else {
                    this.generateCourseAndStudentLabels(data);
                }
            } else {
                console.error("Courses couldn't be fetched.", data.msg);
                this.notification.bad("Courses couldn't be fetched.");
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
        }
    }

    generateCourseAndStudentLabels(data) {
        for (let course of data) {
            const courseItem = this.generateCourseLabel(course);
            this.courses.push(courseItem);
            this.coursesContainer.appendChild(courseItem.dom);
            for (let student of course.students) {
                const studentItem = this.generateStudentLabel(student, course.id);
                this.students.push(studentItem);
                this.studentsContainer.appendChild(studentItem.dom);
            }
        }
    }

    generateCourseLabel(course) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<label class="sessionlog-item sessionlog-course">
                <input 
                    type="radio" 
                    id="course${course.id}" 
                    name="course" 
                    value="${course.id}" 
                    required>
                ${
                    course.name
                    .replace(/ /g, '\u00a0')
                }
            </label>`
            .trim()
            const dom = template.content.firstElementChild;
            const radio = dom.firstElementChild;
            radio.addEventListener("change", () => {
                this.filterStudents(course.id);
            })
            return {
                id: course.id,
                name: course.name,
                dom,
                radio
            };    
    }

    generateStudentLabel(student, course_id) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<label class="sessionlog-item sessionlog-student">
                <input 
                    type="checkbox" 
                    id="${student.id}" 
                    name="student" 
                    value="${student.id}">
                ${student.last_name},&nbsp;${student.first_name}
            </label>`
            .trim()
            const dom = template.content.firstElementChild;
            dom.style.display = "none";
            const checkBox = dom.firstElementChild;
            return {
                id: student.id,
                first_name: student.first_name,
                last_name: student.last_name,
                course_id,
                dom,
                checkBox
            };    

    }

    async fetchCurriculum() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/mentor/get_curriculum`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send courses"})
            });

            const data = await response.json();
            if (response.ok) {
                for (let project of data) {
                    const projectItem = this.generateProjectLabel(project);
                    this.curriculumProjectContainer.appendChild(projectItem.dom);
                    this.projects.push(projectItem);
                }
            } else {
                console.error("Curriculum couldn't be fetched.", data.msg);
                this.notification.bad("Courses couldn't be fetched.");
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
        }
        
    } 

    generateProjectLabel(project) {
        const template = document.createElement("template");
        // .replace(/ /g, '\u00a0') replaces spaces with 
        // non-breaking spaces
        template.innerHTML = 
            `<label class="sessionlog-item sessionlog-project">
                <input 
                    type="radio" 
                    id="project${project.id}"
                    class="curriculum-required-field"
                    name="project" 
                    value="${project.id}">
                ${
                    projectNames[this.language][project.title]
                    .replace(/ /g, '\u00a0')
                }
            </label>`
            .trim()
        const dom = template.content.firstElementChild;
        const radio = dom.firstElementChild;
        return {
            id: project.id,
            title: project.title,
            project,
            dom,
            radio
        };    
    }

    generateLevelLabels() {
        this.removeChildNodes(this.levelsContainer);
        for (let i=1; i<5; i++) {
            const template = document.createElement("template");
            template.innerHTML = 
                `<label class="sessionlog-item level-label">
                    <input 
                        type="radio"
                        id="${levelNames["en"][i-1]}"
                        class="custom-required-field"
                        name="level">
                    <img 
                        class="level-icon" 
                        src="images/project_icons/${this.language}/level_${i}.png" 
                        alt="${levelNames[this.language][i-1]}">
                </label>`
                .trim()
            const dom = template.content.firstElementChild;
            this.levelsContainer.appendChild(dom);
            const radio = dom.firstElementChild;
            this.levels.push({
                level: levelNames["en"][i-1],
                dom,
                radio    
            });
        }        
    }

    generateSkillLabels() {
        this.removeChildNodes(this.skillsContainer);
        Object.entries(skillNames[this.language]).forEach(([key, value]) => {
            const template = document.createElement("template");
            template.innerHTML = 
                `<label class="sessionlog-item skill-label">
                    <input 
                        type="checkbox"
                        id="${key}"
                        class="custom-field"
                        name="skill">
                    <img 
                        class="skill-icon" 
                        src="images/project_icons/${this.language}/${key}.png" 
                        alt="${value}">
                </label>`
                .trim()
            const dom = template.content.firstElementChild;
            this.skillsContainer.appendChild(dom);
            const checkBox = dom.firstElementChild;
            this.skills.push({
                name: key,
                dom,
                checkBox    
            });
        });
    }

    filterStudents(course_id) {
        let counter = 0;
        this.students.forEach( (student) => {
            if (student.course_id == course_id) {
                student.dom.style.display = "inline";
                counter++;
            } else {
                student.dom.style.display = "none";
            }
        });
        this.romaInput.max = counter;
    }

    submitLog() {
        const mentor_id = this.mentor.id;
        const date = this.dateInput.value;
        const course_id = this.courses
            .filter(x=>x.radio.checked)[0].id;
        const students = this.students
            .filter(x => x.checkBox.checked && x.course_id == course_id)
            .map(x => x.id);
        const issues = this.issuesInput.value;
        const roma = this.romaInput.value;
        let project_id,
            project_title,
            size,
            level, 
            skills;
        if (this.toggle.checked) {
            project_id = null;
            project_title = this.customProjectTitleInput.value;
            size = this.sizeOptions.filter(x=>x.checked)[0].value;
            level = this.levels
                .filter(x=>x.radio.checked)[0].level;
            skills = this.skills
                .filter(x => x.checkBox.checked)
                .map(x => x.name);
                
        } else {
            project_id = this.projects
                .filter(x=>x.radio.checked)[0].id;
            project_title = null;
            size = null;
            level = null;
            skills = [];

        }
        const sessionLog = {
            mentor_id,
            date,
            course_id,
            students, 
            roma,
            project_id,
            project_title,
            size,
            level,
            skills,
            issues
        };
        console.log(sessionLog);
        this.sendSessionLog(sessionLog);

    }

    async sendSessionLog(sessionLog) {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/mentor/session_log`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(sessionLog)
            });

            const data = await response.json();
            if (response.ok) {
                console.log("Session log submitted successfully.");
                this.notification.good(
                    "Session log submitted successfully."
                );
            } else {
                console.error("Session couldn't be submitted:", data.msg);
                this.notification.bad(
                    "Submit failed.");
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
            this.backToLogin();
        }
        
    } 


}

new MentorSessionLog();