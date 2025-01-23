class DisplayProgress extends Modal {
    skillNames = [
        "motion", "looks", "messages", "cloning", "variables", 
        "lists", "math", "pen", "sound", "drawing"
    ];
    skills = [];
    levels = ["novice", "intermediate", "advanced", "master"];
    title = "Student progress";

    constructor() {
        super(document.querySelector(".overlay.student-progress"));
        this.getDomElements()
            .addSkills()
            .activateElements();
    }

    getDomElements() {
        this.name = this.overlay.querySelector(".student-name");
        this.skillsContainer = this.overlay.querySelector(".skills-table");
        this.projectsValueArea = this.overlay.querySelector(".value.projects");
        this.totalValueArea = this.overlay.querySelector(".value.total");
        this.closeButton = this.overlay.querySelector(".close-progress");
        return this;

    }

    addSkills() {
        this.skillNames.forEach((name, i) => {
            const skillItem = this.generateSkillItem(name, i);            
            this.skillsContainer.appendChild(skillItem.key);
            this.skillsContainer.appendChild(skillItem.value);
            this.skills.push(skillItem);
        });
        return this;
    }

    activateElements() {
        this.closeButton.addEventListener("click", () => {
            this.exit();
        })
    }

    generateSkillItem(name, i) {
        const keyTemplate = document.createElement("template");
        keyTemplate.innerHTML = 
            `<div class="student-progress skill key">
                <img 
                    src="images/project_icons/en/${name}.png" 
                    alt="${name}">
            </div>`;
        const valueTemplate = document.createElement("template");
        valueTemplate.innerHTML = 
            `<div class="student-progress skill value">0</div>`;
        const key = keyTemplate.content.firstElementChild;
        const value = valueTemplate.content.firstElementChild;
        const id = i+1;
        return {key, value, id, name};
    }

    setStudent(student) {
        this.name.innerHTML = `${student.last_name},&nbsp;${student.first_name}`;
        this.fetchProgressData(student.id);
    }

    async fetchProgressData(student_id) {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/admin/studentprogress`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({msg: "send progress", student_id})
            });

            const data = await response.json();
            if (response.ok) {
                data.forEach((record) => {
                    console.log(record);
                });
                const projectsCounter = data.length;
                const score = this.calculateScore(data);
                console.log(score);
                this.displayScore(projectsCounter, score);
            } else {
                console.error("Progress couldn't be fetched.", data.msg);
                this.notification.show(data.msg, 1000, "bad");
            }
        } else {
            console.error("No token found.");
            this.notification.show("Logged out.", 1000, "bad");
        }
    }


/*  Progress score formula:
        score = sum(skill scores)
        skill score = 3 × level_weight × size_weight
    , where
    level weights:
        novice:         × 1
        intermediate:   × 1.33
        advanced:       × 1.67
        master:         × 2
    size weights:
        miniproject:    × 1
        full project:   × 2
*/
    calculateScore(data) {
        let score = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        for (let record of data) {
            for (let skill of record.skills) {
                let result = 3;
                if (record.size == "full_project") {
                    result *= 2;
                }
                result *= (this.levels.indexOf(record.level) + 3) / 3
                result = Math.round(result);
                score[skill-1] += result;
            }
        }
        return score;
    }

    displayScore(projectsCounter, score) {
        this.projectsValueArea.innerHTML = projectsCounter;
        score.forEach( (s, i) => {
            this.skills[i].value.innerHTML = s;
        });
        const totalScore = score.reduce((subTotal, s) => subTotal + s, 0);
        this.totalValueArea.innerHTML = totalScore;
    }

}