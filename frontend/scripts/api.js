// for a future refactoring, not used yet

class ApiHandler {
    constructor(role) {
        this.role = role;
        this.token = localStorage.getItem("token");
        this.notification = new Notification();
        validate();
    }

    async validate() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/auth/validate/${this.role}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({})
            });
            
            const data = await response.json();
            if (response.ok) {
                this.notification.show("Authorization successful!", 1000, "good");
            } else {
                console.error("Authorization failed:", data.msg);
                this.notification.show(data.msg, 1000, "bad");
            }
        } else {
            console.error("No token found.");
            this.notification.show("Logged out.", 1000, "bad");
            this.timer.delay(() => {
                this.config.redirect("index");
            }, 1000);            
        }
    }

    fetchData(route, ) {

    }

}
