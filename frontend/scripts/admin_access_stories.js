class AdminAccessStories extends AdminAccess {

    constructor() {
        super("Mentor stories");
    }

    start() {
        super.start();
        console.log("hooray, stories");
        this.form.setSubmitEndpoint("/admin/get_stories");
        this.form.setForwardData(this.displayStory);
    }

    displayStory(data) {
        console.log("story:", data);
    }
}

new AdminAccessStories();