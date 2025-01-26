class MentorPhotos extends MentorPage {

    start() {
        super.start("Upload photos");
        this.form = new Form(this.pageContent, "/mentor/submit_photos");
        this.form.setNotification(this.notification);
        const now = new Date;
        this.form.fillWith({date: now});
        this.setImageValidation();
        this.fetchMentorData(); // async
    }

    getDomElements() {
        super.getDomElements();
        this.mentorArea = document.querySelector(".photos-mentor-name");
        this.imageInput = document.querySelector("#image-input");
    }

    setImageValidation() {
        this.imageInput.addEventListener("change", () => {
            const maxSize = 12 * 1024 * 1024; // 10 MB
            let totalSize = 0;
            [...this.imageInput.files].forEach(file => totalSize += file.size);
            if (maxSize < totalSize) {
                this.imageInput.value = "";
                this.notification.bad("Max. 12 MB!");
            }
        })
    }

    setLanguage(lang) {
        super.setLanguage(lang)
        this.header.setTitle(photosTitle[lang]);
    }

    async fetchMentorData() {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/mentor/get_mentor_data`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send courses"})
            });

            const data = await response.json();
            if (response.ok) {
                this.mentor = data;
                this.mentorArea.innerHTML = `${data.last_name}, ${data.first_name}`;

            } else {
                console.error("Mentor data couldn't be fetched.", data.msg);
                this.notification.bad(data.msg);
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
        }
            
    }

}

new MentorPhotos();