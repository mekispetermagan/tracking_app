class Gem {
  colors = ["blue", "red", "turquoise"];
  timer = new Timer();
  random = new Random();
  counter = 0;
  sparkleAngle = 0;
  sparkleAngleDiff = 6;
  constructor(colorIndex, container) {
    this.color = this.colors[colorIndex];
    const template = document.createElement("template");
    template.innerHTML = 
      `<div class="student-gem-frame">
        <img class="student-gem" src="images/gems/gem_${this.color}.svg">
        <img class="student-sparkle" src="images/gems/sparkle.svg">
      </div>`;
    this.dom = template.content.firstElementChild;
    this.gem = this.dom.firstElementChild;
    this.sparkle = this.dom.lastElementChild;
    container.appendChild(this.dom);
    this.animate();
  }

  animate() {
    this.reposition();
    this.timer.forever(() => {
      this.counter++;
      this.turn();
      if (this.counter % 60 == 0) {this.reposition();}
      // if (this.random.randInt(1,20) == 1) {this.reposition();}
    },50);
  }

  turn() {
    this.sparkleAngle += this.sparkleAngleDiff;
    this.sparkle.style.transform = `translate(-50%,-50%) rotate(${this.sparkleAngle}deg)`
  }

  reposition() {
    this.sparkle.style.left = `${this.random.randInt(10,35)}px`;
    this.sparkle.style.top = `${this.random.randInt(10,30)}px`;
  }

}

class StudentPage {
  random = new Random();
  timer = new Timer();
  constructor() {
    this.studentId = localStorage.getItem("student_id");
    console.log(this.studentId);
    this.getDomElements();
    this.animateAvatar(0);
    this.fetchStudentProgress(); //async
    this.addGem();
  }

  getDomElements() {
    this.avatarFrames = document.querySelectorAll(".avatar-image");
    this.gemContainer = document.querySelector(".gem-container");
  }

  animateAvatar(nextFrame) {
    if (nextFrame == 0) {
      this.avatarFrames[0].classList.remove("undisplayed");
      this.avatarFrames[1].classList.add("undisplayed");
      this.timer.delay(() => {
        this.animateAvatar(1);
        },
        this.random.randInt(1000, 3000)
      );
    } else {
      this.avatarFrames[0].classList.add("undisplayed");
      this.avatarFrames[1].classList.remove("undisplayed");
      this.timer.delay(() => {
        this.animateAvatar(0);
      },
        100
      );
    }
  }

  async fetchStudentProgress() {
    const response = await fetch(`${window.API_BASE_URL}/api/student/get_student_progress`, {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json',
      },
      body: JSON.stringify({"msg": "send student data", "id": this.studentId})
    });
  
    const data = await response.json();
      if (response.ok) {
        this.studentProgress = data;
        console.log(this.studentProgress);
      } else {
      console.error("Didn't get student progress data:", data.msg);
    }
  }

  addGem() {
    const newGem = new Gem(1, this.gemContainer);
  }

}

new StudentPage();