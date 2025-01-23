class PasswordChange extends AuthPage {

    constructor() {
        super("temporary");
        this.header = new Header("Change password", "post_login");
    }

    start() {
        this.getDomElements();
        this.fetchEmail();
    }

    getDomElements() {
        this.pwdchForm = document.querySelector(".pwdchange-form")
        this.pwdchForm.addEventListener("submit", (event) => {
            this.handlePwdChange(event)
        });
        this.emailField = document.querySelector(".email-field");
        this.cancelButton = document.querySelector(".cancel");
        this.cancelButton.addEventListener("click", (e) => {
            this.config.redirect("post_login");
        });
        this.oldPwdInput = document.querySelector("#oldpassword");
        this.newPwdInput = document.querySelector("#newpassword");
        this.confirmPwdInput = document.querySelector("#confirm-newpassword");
        return this;
    }

    async fetchEmail() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/shared/get_email`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send courses"})
            });

            const data = await response.json();
            if (response.ok && data.email) {
                this.emailField.innerHTML = data.email;
                this.notification.good("Email fetched.");
                console.log("Email fetched successfully.");

            } else {
                console.error("Email couldn't be fetched.", data.msg);
                this.notification.bad("Email couldn't be fetched.");
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
        }
    }

    async handlePwdChange(event) {
        event.preventDefault();
        const oldPassword = this.oldPwdInput.value;
        const newPassword = this.newPwdInput.value;
        const newPassword2 = this.confirmPwdInput.value;
        if (newPassword == newPassword2) {
            const token = localStorage.getItem("token");
            if (token) {
                const response = await fetch(`${window.API_BASE_URL}/api/auth/passwdchange`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({oldPassword, newPassword})
                });
                
                const data = await response.json();
                if (response.ok) {
                    clearTimeout(this.redirectTimeout);
                    this.notification.good("Password changed <br>successfully!");
                    this.redirectTimeout = setTimeout(() => {redirect("index")}, 1200);
                } else {
                    this.notification.bad("Password change failed.");
                    console.error("Password change failed:", data.msg);
                }
            } else {
                console.error("No token found.");
            }
        } else {
            this.notification.bad("Passwords don't match!");
        }
    }

}


new PasswordChange();