// index.html

class Login extends Page{
    constructor() {
        super();
        this.emptyStorage();
        this.getDomElements();
    }

    // removes residual data from previous login
    emptyStorage() {
        ["token", "mentors", "roles", "role"].forEach((item) => {
            localStorage.removeItem(item);
        });
    }

    getDomElements() {
        this.loginForm = document.querySelector("form");
        this.loginForm.addEventListener("submit", (event) => {
            this.handleLogin(event);
        });
        this.loginEmail = document.getElementById('email');
        this.loginPwd = document.getElementById('password');
    }

    async handleLogin(event) {
        event.preventDefault();
        const email = this.loginEmail.value; 
        this.email = email;
        const password = this.loginPwd.value;
        // send login request
        const response = await fetch(`${window.API_BASE_URL}/api/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email, password })
        });
        // handle response
        const data = await response.json();
        if (response.ok) {
            // save token
            localStorage.setItem('token', data.access_token);
            this.notification.good("Login successful!");
            console.log("Login successful!");
            if (data.roles) {
                localStorage.setItem('roles', JSON.stringify(data.roles));
            } else if (data.mentors) {
                localStorage.setItem('mentors', JSON.stringify(data.mentors));
            } else if (data.role) {
                localStorage.setItem('role', JSON.stringify(data.role));
            }
            this.config.redirect("post_login");
        } else {
            alert('Login failed: ' + data.msg);
        }
    }

}

new Login();