class MentorProfilePage extends MentorPage {

    constructor() {
        super("My data");
        this.form = new Form(
            document, 
            "/mentor/submit_profile"
        );
        this.form.setNotification(this.notification);
        this.getDomElements();
    }
    
    start() {
        this.setLanguage(this.preferredLanguage)
        this.form.fetchPrefillData("/mentor/get_profile_data");
        this.form.setExitFunction(() => this.config.redirect("mentor"));
    }

    getDomElements() {
        this.languageTextFields = [...
            document.querySelectorAll(".language-text")
        ];
    }

    setLanguage(language) {
        this.language = language
        this.languageMenu.adjustMenu(language)
        this.header.setTitle(mentorProfileTitle[language]);
        this.languageTextFields.forEach((item, i) => {
            item.innerHTML = mentorProfileTexts[language][i];
        });
    }
}

new MentorProfilePage();