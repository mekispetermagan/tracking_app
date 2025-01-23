class AdminManageMentors extends AdminPage {
    mentorListItems = [];
    selectedMentor = null;
    
    constructor() {
        super("Manage mentors");
    }

    async start() {
        this.getDomElements()
            .createFilters()
            .createModals()
            .activateButtons();
        await this.fetchMentors();
    }

    getDomElements() {
        this.mentorlistArea = document.querySelector(".listmenu-list");
        this.addMentorButton = document.querySelector(".listmenu-button.add");
        this.editMentorButton = document.querySelector(".listmenu-button.edit");
        this.filterArea = document.querySelector(".filter-container");
        return this;
    }
    
    createModals() {
        this.addEditMentor = new AddEditMentor();
        this.addEditMentor.setExitMethod(() => {
            this.closeModal(this.addEditMentor);
        });
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
    
    activateButtons() {
        this.addMentorButton.addEventListener("click", () => {
            this.selectedMentor = null;
            this.openModal(this.addEditMentor);
        });
        this.editMentorButton.addEventListener("click", () => {
            if (this.selectedMentor) {
                this.openModal(this.addEditMentor);
            } else {
                this.notification.show("No mentor selected!", 2000);
            }
        });
        return this;
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

    disableInterface() {
        for (let item of this.mentorListItems) {
            item.radio.disabled = true;
            this.addMentorButton.disabled = true;
            this.editMentorButton.disabled = true;
            }
            this.filters.disable();
    }

    enableInterface() {
        for (let item of this.mentorListItems) {
            item.radio.disabled = false;
        }
        this.addMentorButton.disabled = false;
        this.editMentorButton.disabled = false;
        this.filters.enable();
    }

    openModal(modal) {
        modal.setMentor(this.selectedMentor);
        this.disableInterface();
        this.header.setTitle(modal.mentor ? modal.title.edit : modal.title.add);
        modal.open();
    }

    closeModal(modal) {
        this.enableInterface();
        this.header.resetTitle();
        modal.close();
        this.fetchMentors(); // async
    }

}

new AdminManageMentors();


