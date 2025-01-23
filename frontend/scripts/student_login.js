class StudentLogin {
  colors = [
    ["red", "blue", "yellow", "green"], 
    ["orange", "purple", "pink"], 
    ["brown", "cyan", "lime", "gray"]
  ];
  mascots = [
    "bear", "beetle", "butterfly", "cat", "dog",
    "elephant", "giraffe", "hedgehog", "pony", "owl",
    "rabbit"
  ]
  colorButtons = [];
  mascotImages = [];
  selectedMascot = null;
  selectedColor = null;
  studentData = null;

  constructor() {
    this.getHash();
    this.getDomElements();
    this.generateColorButtons();
    this.fetchStudentData(); // async
    this.generateMascotImages(); // async
    this.timer = new Timer();
    this.config = new Config();
  }

  getHash() {
    const url = new URL(window.location.href);
    this.studentUserId = parseInt(url.hash.slice(1));
    console.log(this.studentUserId)
  }

  getDomElements() {
    this.page = document.querySelector(".student-login-page");
    this.colorButtonAreas = this.page.querySelectorAll(".color-container");
    this.mascotImageArea = this.page.querySelector(".mascot-container");
    this.nameArea = this.page.querySelector(".student-name");
    this.loginButton = this.page.querySelector(".login-button");
    this.loginButton.disabled = true;
    this.loginButton.addEventListener("click", () => {
      this.attemptLogin();
    })
  }

  async fetchStudentData() {
    const response = await fetch(`${window.API_BASE_URL}/api/student/get_student_data`, {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json',
      },
      body: JSON.stringify({"msg": "send student data", "id": this.studentUserId})
    });
  
    const data = await response.json();
      if (response.ok) {
        this.studentData = data;
        console.log(this.studentData);
        this.fillNameArea();
      } else {
      console.error("Didn't get student data:", data.msg);
    }
  }

  fillNameArea() {
    const name = `${this.studentData.first_name}, ${this.studentData.last_name}`;
    this.nameArea.innerHTML = name;
  }

  generateColorButtons() {
    let counter = 1;
    this.colors.forEach((row, i) => {
      row.forEach((color, j) => {
        const button = document.createElement("button");
        button.classList.add("student-login");
        button.classList.add("color-button");
        button.style.backgroundColor = `var(--color-${color})`;
        this.colorButtonAreas[i].appendChild(button);
        this.colorButtons.push(button);
        const id = counter;
        button.addEventListener("click", () => {
          this.selectColorButton(button, color, id);
        });
        counter++;
      });
    }); 
  }

  selectColorButton(button, color, color_id) {
    this.selectedColor = color_id;
    this.checkIfSubmitReady();
    this.page.style.setProperty(
      '--mascot-color', `var(--color-${color})`
    );
    const resolvedColor = getComputedStyle(this.page)
    .getPropertyValue(`--color-${color}`);
    this.mascotFillPaths.forEach((element) => {
      element.style.fill = resolvedColor;
    });
    this.colorButtons.forEach((b) => {
      if (b == button) {
        b.classList.add("selected");
      } else {
        b.classList.remove("selected");
      }
    });
  }

  generateMascotImages() {
    Promise.all(this.mascots
      .map(mascot => `images/student_login/${mascot}.svg`)
      .map(url => fetch(url).then(res => res.text())))
      .then(svgs => {
        svgs.forEach((svg, i) => {
          this.mascotImageArea.scrollLeft = 0;
          const template = document.createElement("template");
          template.innerHTML = 
            `<div class="mascot-image">
                ${svg}
            </div>`;
          const dom = template.content.firstElementChild;
          this.mascotImageArea.appendChild(dom);
          const mascotImage = {
            dom: dom,
            pos: i-5,
            id: i+1
          }
          this.mascotImages.push(mascotImage);
          this.activateMascotImage(mascotImage);
        });
        this.mascotFillPaths = document.querySelectorAll(".mascot-fill");
        this.adjustMascotImages();
      })
    .catch(error => console.error('Error fetching SVGs:', error));
  }

  selectMascot() {
    this.mascotImages.forEach( (image) => {
      if (this.selectedMascot && image.pos == 0) {
        this.selectedMascot = image.id;
        image.dom.classList.add("selected");
      } else {
        image.dom.classList.remove("selected");
      }
    });
  }

  adjustMascotImages() {
    const center = parseFloat(
      window
        .getComputedStyle(this.mascotImageArea)
        .width
    ) / 2;
    this.mascotImages.forEach( (image, i) => {
      let absPos;
      if (image.pos < 0) {
        absPos = center * (
          0.5**Math.abs(image.pos)
        );
      } else {
        absPos = center * (
          2 - 
          (0.5**Math.abs(image.pos))
        );
      }
      image.dom.style.left = `${absPos - 60}px`;
      image.dom.style.transform = `scale(${
        0.6**Math.abs(image.pos)
      })`;
      image.dom.style.zIndex = `${
        10 - Math.abs(image.pos)
      }`;
    });
    this.checkIfSubmitReady();
  }

  activateMascotImage(image) {
    image.dom.addEventListener("click", (e) => {
      if (image.pos == 0 && !this.selectedMascot) {
          this.selectedMascot = image.id;
        } else if (image.pos < 0) {
          this.previousMascot();
        } else {
          this.nextMascot();
        }
        this.selectMascot();
        this.adjustMascotImages();
      });
  }

  nextMascot() {
    this.mascotImages.forEach(image => {
      image.pos = ((image.pos + 15) % 11) - 5;
    });
  }

  previousMascot() {
    this.mascotImages.forEach(image => {
      image.pos = ((image.pos + 6) % 11) - 5;
    });
  }

  checkIfSubmitReady() {
    if (this.selectedColor && this.selectedMascot) {
      this.loginButton.classList.add("submit-ready");
      this.loginButton.disabled = false;
    }
  }

  attemptLogin() {
    console.log("login attempt:");
    console.log("Mascot:", this.selectedMascot);
    console.log("Color:", this.selectedColor);
    if (
      this.studentData.color_id == this.selectedColor &&
      this.studentData.mascot_id == this.selectedMascot
    ) {
      console.log("Success!");
      localStorage.setItem("student_id", this.studentData.id);
      this.config.redirect("student");
    } else {
      console.log("Failure!");
      this.resetSelections();
    }
  }

  resetSelections() {
    this.selectedMascot = null;
    this.mascotImages.forEach((image) => {
      image.dom.classList.remove("selected");
    });
    this.selectedColor = null;
    this.colorButtons.forEach((button) => {
      button.classList.remove("selected");
    });
    this.loginButton.classList.remove("submit-ready");
    this.loginButton.disabled = false;
  }

}

new StudentLogin();