class AdminPhoto extends AdminAccess {

    constructor() {
        super("Mentor photos");
    }

    start() {
        super.start();
        console.log("hooray, photos");
        this.form.setSubmitEndpoint("/admin/get_photos");
        this.form.setForwardData((data) => this.displayPhotos(this, data));
        console.log(this)
    }

    getDomElements() {
        super.getDomElements();
        this.photoArea = document.querySelector(".photo-display");
        console.log(this.photoArea)
        return this;
    }

    displayPhotos(page, data) {
        removeChildNodes(page.photoArea);
        console.log("photos:", data);
        const fileNames = data["paths"];
        const dir = data["dir"];
        fileNames.forEach(name => {
            const photo = new Image();
            photo.src = `${baseURL}/${dir}/${name}`;
            photo.classList.add("mentor-photo");
            page.photoArea.appendChild(photo);
        });
    }

}

new AdminPhoto()