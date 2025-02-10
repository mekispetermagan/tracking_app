class AdminPhoto extends AdminAccess {

    constructor() {
        super("Mentor photos");
    }

    start() {
        super.start();
        console.log("hooray, photos");
        this.form.setSubmitEndpoint("/admin/get_photos");
        this.form.setForwardData(this.displayPhotos);
    }

    displayPhotos(data) {
        console.log("photos:", data);
    }

}

new AdminPhoto()