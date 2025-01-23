
class AdminMenu extends AdminPage {
    constructor() {
        super("Admin menu");
        this.config = new Config();
    }

    start() {
        this.getDomElements();
    }
    
    getDomElements() {
        const pageButtons = [...document.querySelectorAll(".admin-menu-button")];
        for (let button of pageButtons) {
            button.addEventListener("click", (e) => {
                this.config.redirect(button.id);
            })
        }
        return this;
    }

}

new AdminMenu();