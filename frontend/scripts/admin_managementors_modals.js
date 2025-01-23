class AddEditMentor extends Modal {
    title = {
        add: "Add mentor", 
        edit: "Edit mentor"
    };
    mentor = null;

    constructor() {
        const overlay = document.querySelector(".overlay.add-mentor")
        super(overlay);
        this.getDomElements();
    }

    getDomElements() {
        this.cancelButton = this.overlay.querySelector("button.cancel");
        this.cancelButton.addEventListener("click", (e) => {
            e.preventDefault();
            this.exit();
        })
        const formArea = this.overlay.querySelector("#add-mentor-form");
        this.pwdUnchangedArea = formArea.querySelector("#password-unchanged");
        this.form = {
            firstName: formArea.querySelector("#first-name"),
            lastName: formArea.querySelector("#last-name"),
            preferredLanguage: formArea.querySelector("#preferred-language"),
            country: formArea.querySelector("#country"), 
            email: formArea.querySelector("#email"),
            pwdUnchanged: formArea.querySelector("#password-unchanged-input"),
            password: formArea.querySelector("#password"),
            active: formArea.querySelector("#active"),
            };
        this.form.pwdUnchanged.addEventListener("change", () => {
            this.togglePasswordDisabled();
        });
        formArea.addEventListener("submit", (event) => {this.handleSubmission(event);});
    }

    clearData() {
        this.form.firstName.value = "";
        this.form.lastName.value = "";
        this.form.email.value = "";
        this.form.preferredLanguage.value = "";
        this.form.password.value = "";
        this.form.active.checked = true
    }

    fillData() {
        console.log(this.mentor)
        this.form.firstName.value = this.mentor.first_name;
        this.form.lastName.value = this.mentor.last_name;
        this.form.preferredLanguage.value = this.mentor.preferred_language;
        this.form.country.value = this.mentor.country_id;
        this.form.email.value = this.mentor.email;
        this.form.password.value = "";
        this.form.active.checked = this.mentor.active;
    }

    async handleSubmission(event) {
        event.preventDefault();
        const firstName = this.form.firstName.value;
        const lastName = this.form.lastName.value;
        const preferredLanguage = this.form.preferredLanguage.value;
        const countryId = this.form.country.value;
        const email = this.form.email.value;
        const pwdUnchanged = this.form.pwdUnchanged.checked;
        const password = pwdUnchanged ? "unchanged" : this.form.password.value;
        const active = this.form.active.checked;
        let mode, userId;
        if (this.mentor) {
            mode = "edit";
            userId = this.mentor.user_id;
        } else {
            mode = "add";
            userId = null;
        }
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/admin/manage_mentor`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ 
                    mode,
                    userId,
                    firstName, 
                    lastName, 
                    preferredLanguage,
                    countryId, 
                    email,
                    pwdUnchanged,
                    password,
                    active
                })
            });
            const data = await response.json();
            if (response.ok) {
                // save token
                console.log(data.msg)
                this.notification.show("Success!", 1000, "good");
                this.timer.delay(() => {
                    this.exit();
                }, 500);
            } else {
                console.log("There was an error: " + data.msg);
                this.notification.show(data.msg, 2000, "bad");
            }
        } else {
            this.config.redirect("index");
        }
    }

    togglePasswordDisabled() {
        this.form.password.disabled = this.form.pwdUnchanged.checked;
    }

    setMentor(mentor) {
        this.mentor = mentor;
    }

    open() {
        super.open();
        if (this.mentor) {
            this.fillData();
            this.pwdUnchangedArea.classList.remove("undisplayed");
            this.form.pwdUnchanged.checked = true;
        } else {
            this.pwdUnchangedArea.classList.add("undisplayed");
            this.clearData()
            this.form.pwdUnchanged.checked = false;
        }
        this.togglePasswordDisabled();
    }

}
