class PostLogin extends AuthPage {

    constructor() {
        super("temporary");
        this.getDomElements()
            .activatePasswordButton()
            .generateButtons();
    }

    getDomElements() {
        this.buttonArea = document.querySelector(".page-content.post-login");
        this.passwordButton = document.querySelector(
            "#pwdchange"
        );
        return this;
    }

    activatePasswordButton() {
        this.passwordButton.addEventListener(
            "click", 
            () => this.config.redirect("password_change")
        );
        return this;
    }

    generateButtons() {
        const mentors = JSON.parse(localStorage.getItem("mentors"));
        const roles = JSON.parse(localStorage.getItem("roles"));
        const role = JSON.parse(localStorage.getItem("role"));
        if (mentors) {
            mentors.forEach(mentor => this.createMentorButton(mentor));
        }
        else if (roles) {
            roles.forEach(role => this.createRoleButton(role));
        } else if (role) {
            this.createContinueButton(role);
        }
        return this;
    }

    createRoleButton(role) {
        const capitalFirst = 
            (text) => text.charAt(0).toUpperCase() + text.slice(1);
        const template = document.createElement("template");
        template.innerHTML = `
            <button class="choice-button ${role}">  
                Continue as ${capitalFirst(role)}
            </button>`;
        const button = template.content.firstElementChild;
        this.buttonArea.appendChild(button);
        button.addEventListener("click", () => this.specifyRole(role));
    }

    createMentorButton(mentor) {
        const template = document.createElement("template");
        template.innerHTML = `
            <button class="choice-button mentor">
                ${mentor.first_name}, ${mentor.last_name}
            </button>`;
        const button = template.content.firstElementChild;
        this.buttonArea.appendChild(button); 
        button.addEventListener("click", () => this.specifyMentor(mentor.id));
    }

    createContinueButton(role) {
        const template = document.createElement("template");
        template.innerHTML = `
            <button class="choice-button ${role}">
                Continue
            </button>`;
        const button = template.content.firstElementChild;
        this.buttonArea.appendChild(button); 
        button.addEventListener("click", () => this.config.redirect(role));
    }

    async specifyRole(role) {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/auth/specify_role`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({role})
        });
        
        const data = await response.json();
        if (response.ok) {
            localStorage.setItem('token', data.access_token);
            localStorage.removeItem("roles");
            this.config.redirect(role);
        } else {
            console.error("Role choice rejected by server!");
            this.notification.bad("Role choice rejected!");
        }
    }

    async specifyMentor(mentorId) {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/auth/specify_mentor`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({"mentor_id": mentorId})
        });
        
        const data = await response.json();
        if (response.ok) {
            localStorage.setItem('token', data.access_token);
            localStorage.removeItem("mentors");
            this.config.redirect("mentor");
        } else {
            console.error("Mentor choice rejected by server!");
            this.notification.bad("Mentor choice rejected!");
        }
    }

    activatePasswordChangeButton() {

    }

}


new PostLogin();