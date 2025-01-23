class MentorInvoice extends MentorPage {
    constructor() {
        super("Submit invoice");
        this.languageMenu = new LanguageMenu((lang) => {
            this.setLanguage(lang);
        });
        this.getDomElements();
        this.form = new Form(this.page, "/mentor/submit_invoice");
        this.form.setFormName("Invoice");
        this.form.setNotification(this.notification);
    }

    start() {
        this.setLanguage(this.preferredLanguage);
        this.form.fetchPrefillData("/mentor/get_invoice_data");
        const today = new Date().toISOString().split("T")[0]; // ISO 8601
        const thisMonth = today.slice(0, 7); // "YYYY-MM" 
        this.form.fillField("date", today);
        this.form.fillField("period", thisMonth);
    }

    getDomElements() {
        this.page = document.querySelector(".page");
        this.textFields = this.page.querySelectorAll(".invoice-text")
    }

    setLanguage(language) {
        this.language = language
        this.languageMenu.adjustMenu(language)
        this.header.setTitle(invoiceTitle[language]);
        this.textFields.forEach((field, i) => {
            field.innerHTML = invoiceTexts[language][i];
        });
    }

} // MentorInvoice

new MentorInvoice();