class MentorMenu extends MentorPage {
    constructor() {
        super("Mentor interface");
    }

    start() {
        console.log(this.preferredLanguage);
        this.getDomElements()
            .setLanguage(this.preferredLanguage)
            .activateMenu();
    }

    getDomElements() {
        super.getDomElements();
        this.menuButtons = [...document.querySelectorAll(".mentormenu-button")];

        return this;
    }

    activateMenu() {
        const redirects =
            [ "mentor_profile"
            , "mentor_sessionlog"
            , "mentor_managestudents"
            , "mentor_invoice"
            , "mentor_photos"
            , "mentor_story"
            ];
        this.menuButtons.forEach((button, i) => {
            button.addEventListener("click", () => {
                this.config.redirect(redirects[i]);
            });
        });
        return this;
    }

    setLanguage(language) {
        super.setLanguage(language);
        this.header.setTitle(mentorPageTitle[language]);
        return this;
    }
}

new MentorMenu();