class AdminAccessStatistics extends AdminPage {
    country = "all";
    year = "all";  

    constructor() {
        super("Basic statistics");
    }

    async start() {
        this.getDomElements()
            .activateButtons();
        await this.fetchStatistics();
    }

    getDomElements() {
        this.coursesDisplay = document.querySelector(".statistics-value.courses");
        this.mentorsDisplay = document.querySelector(".statistics-value.mentors");
        this.sessionsDisplay = document.querySelector(".statistics-value.sessions");
        this.studentsDisplay = document.querySelector(".statistics-value.students");
        this.countryButtons = [...document.querySelectorAll("input[name='country']")];
        this.yearButtons = [...document.querySelectorAll("input[name='year']")];
        return this;
    }
    
    activateButtons() {
        this.countryButtons.forEach(button => {
            button.addEventListener("change", () => {
                this.country = button.value;
                console.log(this.country);
                this.fetchStatistics();
            });
        });
        this.yearButtons.forEach(button => {
            button.addEventListener("change", () => {
                this.year = button.value;
                console.log(this.year);
                this.fetchStatistics();
            });
        });
        return this;
    }

    async fetchStatistics() {
        const token = localStorage.getItem("token");
        const response = await fetch(`${window.API_BASE_URL}/api/admin/get_statistics`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
              "msg": "send statistics",
              "country": this.country,
              "year": this.year,
            })
        });
        
        const data = await response.json();
        if (response.ok) {
            console.log("statistics:", data)
            this.notification.show("Statistics loaded!", 2000, "good");
            this.displayStatistics(data);
        } else {
            console.error("Didn't get statistics!");
            this.notification.show("Didn't get statistics!", 2000, "bad");
        }
        return this;
    }

    displayStatistics(data)  {
        this.coursesDisplay.innerHTML = data["courses"];
        this.mentorsDisplay.innerHTML = data["mentors"];
        this.sessionsDisplay.innerHTML = data["sessions"];
        this.studentsDisplay.innerHTML = data["students"];
    }


}

new AdminAccessStatistics();


