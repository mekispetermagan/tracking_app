class AdminAccess extends AdminPage {
    constructor(title) {
        super(title);
    }

    start() {
        this.getDomElements()
            .createForm()
            .createFilters()
            .fetchMentors(); // async
    }

    getDomElements() {
        this.mentorlistArea = document.querySelector(".mentor-list");
        this.filterArea = document.querySelector(".filter-container");
        return this;
    }

    createForm() {
        this.form = new Form(this.container, "");
        this.form.setNotification(this.notification);
        const now = new Date();
        const month = now.getMonth() + 1;
        const year = now.getFullYear();
        this.form.fillWith({year: year, month: month});
        return this;
    }

    createFilters() {
        this.filters = new Filters(
            this.filterArea,
            this.filterMentors.bind(this)
        )
        return this;
    }

    filterMentors() {
        console.log(this.mentorListItems[0]);
        const filteredMentors = this.filters.filterList(this.mentorListItems);
        console.log(filteredMentors);
        this.mentorListItems.forEach(name => {
            if (filteredMentors.includes(name)) {
                name.dom.classList.remove("undisplayed");
            } else {
                name.dom.classList.add("undisplayed");
            }
        })
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
            this.notification.show("Mentor list loaded!", 2000, "good");
            const mentors = this.sortByName(data);
            this.generateMentorList(mentors);
        } else {
            console.error("Didn't get mentor data!");
            this.notification.show("Didn't get mentor data!", 2000, "bad");
        }
        return this;
    }


    sortByName(data) {
        data.sort((a, b) => {
        // First, compare by last name
        let lastNameComparison = a.last_name.localeCompare(b.last_name, ["hu", "sk", "en"]);
        if (lastNameComparison !== 0) {
            return lastNameComparison;  // If last names are different, return the comparison result
        }
        // If last names are the same, compare by first name
        return a.first_name.localeCompare(b.first_name, ["hu", "sk", "en"]);
        });
        return data;
    }

    generateMentorList(mentors) {
        this.removeChildNodes(this.mentorlistArea);
        this.mentorListItems = [];
        for (let mentor of mentors) {
            const listItem = this.createMentorListItem(mentor);
            this.mentorlistArea.appendChild(listItem.dom);
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
            `<li class="listmenu-list-item">
                <label><input type="radio" name="mentor" value="${mentor.user_id}">
                    ${mentor.last_name}, ${mentor.first_name}
                </label>
            </li>`.trim();
        mentor.dom = template.content.firstElementChild;
        mentor.radio = mentor.dom.firstElementChild.firstElementChild;
        mentor.radio.addEventListener("change", () => {
            this.selectedMentor = mentor;
        });
        return mentor;
    }

}
