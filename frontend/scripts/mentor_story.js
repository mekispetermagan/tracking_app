class MentorStory extends MentorPage {
    courses = [];
    constructor() {
        super("Story of the month");
    }

    start() {
        super.start();
        this.form = new Form(this.pageContent, "/mentor/submit_story");
        this.form.setNotification(this.notification);
        this.fetchMentorData(); // async
        this.fetchCourses(); // async

    }

    getDomElements() {
        super.getDomElements();
        this.mentorArea = document.querySelector(".story-mentor-name");
        this.coursesArea = document.querySelector(".courses-container");
        this.storyField = document.querySelector("textarea[name='story']");
        this.storyField.innerHTML = "";
    }

    setLanguage(lang) {
        super.setLanguage(lang)
        this.header.setTitle(storyTitle[lang]);
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
                this.mentorArea.innerHTML = `${data.last_name}, ${data.first_name}`;

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
                    this.coursesArea.insertAdjacentHTML(
                        "beforeend",
                        noCourseMessage[this.language]
                    );
                } else {
                    this.generateCourseLabels(data);
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

    generateCourseLabels(data) {
        for (let course of data) {
            const courseItem = this.createCourseLabel(course);
            this.courses.push(courseItem);
            this.coursesArea.appendChild(courseItem.dom);
        }
    }

    createCourseLabel(course) {
        const template = document.createElement("template");
        template.innerHTML = 
            `<label class="sessionlog-item sessionlog-course">
                <input 
                    type="radio" 
                    id="course${course.id}" 
                    name="course_id" 
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
            return {
                id: course.id,
                name: course.name,
                dom,
                radio
            };    
    }


}

new MentorStory();