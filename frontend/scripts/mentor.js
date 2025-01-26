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
        this.language = language
        this.languageMenu.adjustMenu(language)
        this.header.setTitle(mentorPageTitle[language]);
        this.menuButtons.forEach((button, i) => {
            button.innerHTML = mentorPageTexts[language][i];
        });
        return this;
    }
}

new MentorMenu();