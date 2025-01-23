// TODO: write this
// For now, this is a draft for a later refactoring of the codebase.
// The classes are not used in any of the pages.

// A general page for managing mentors, courses, and students
// with "Add" and "Edit" functionalities in modals

// primary:   type of the object added or edited
// secondary: type of the object linked to primary
// (mentor, course, student)
// mentor management:
//    primary:   mentor
//    secondary: null
// course management:
//    primary:   course
//    secondary: mentor
// student management:
//    primary:   student
//    secondary: course

// Classes:
//    - ManageModal
//    - ManagePage


class ManageModal extends Modal {
  primary = null;
  secondaryListItems = [];

  constructor(role, primaryName, secondaryName) {
    const overlay = document.querySelector(`.overlay.manage`)
    super(overlay);
    this.overlay = overlay;
    this.title = {
      add: `Add ${primaryName}`, 
      edit: `Edit ${primaryName}`
    };  
    this.role = role;
    this.form = new Form(this.overlay)
    this.primaryName = primaryName;
    this.secondaryName = secondaryName
    this.getDomElements();
    this.fetchSecondaries(); // async
  }

  getDomElements() {
    this.cancelButton = this.overlay.querySelector("button.cancel");
    this.cancelButton.addEventListener("click", (e) => {
      e.preventDefault();
      this.exit();
    })
    // const formArea = this.overlay
    //   .querySelector(".manage-form");
    this.secondaryListArea = this.overlay.querySelector(".secondary-list");
  }

  async fetchSecondaries() {
    const token = localStorage.getItem("token");
    const response = await fetch(`${window.API_BASE_URL}/api/${this.role}/${this.secondaryName}list`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({"msg": "send courselist"})
    });
    
    const data = await response.json();
    if (response.ok) {
      this.generateSecondaryList(data);
    } else {
      console.error(`Didn't get ${secondary} data!`);
    }
  }

  generateSecondaryList(secondaries) {
    removeChildNodes(this.secondaryListArea);
    this.secondaryListItems = [];
    for (let secondary of secondaries) {
      const listItem = this.createSecondaryListItem(secondary);
      this.secondaryListArea.appendChild(listItem.dom);
      this.secondaryListItems.push(listItem);
    }
  }

  createSecondaryListItem(secondary) {
    const template = document.createElement("template");
    template.innerHTML = 
      `<li class="course-list-item">
        <label><input type="checkbox" name="course" value="${secondary.id}"> 
          ${secondary.name}
        </label>
      </li>`.trim();
    const listItemDom = template.content.firstElementChild;
    const checkBox = listItemDom.firstElementChild.firstElementChild;
    checkBox.addEventListener("change", () => {
      console.log(secondary.id)
    });
    return {
      secondary: secondary,
      dom: listItemDom,
      checkBox: checkBox,
    }
  }

  clearData() {
    this.form.clear()
    this.secondaryListItems.forEach((item) => {
      item.checkBox.checked = false;

    });
  }

  fillData() {
    this.form.fillWith(this.primary)
      this.secondaryListItems.forEach((item) => {
        if (this.primary[`${this.secondaryName}s`].includes(item.secondary.id)) {
          item.checkBox.checked = true;
          console.log("id:", item.secondary.id);
        } else {
          item.checkBox.checked = false;
        }
      });
  }

  async handleSubmission() {
    const secondaryIds = this.getSelectedSecondaryIds();
    console.log(courseIds);
    let mode, studentId;
    if (this.student) {
        mode = "edit";
        studentId = this.student.id;
    } else {
        mode = "add";
        studentId = null;
    }
    const token = localStorage.getItem("token");
    if (token) {
      const response = await fetch(`${window.API_BASE_URL}/api/${role}/manage_${this.primaryName}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          mode,
          studentId,
          firstName,
          lastName, 
          courseIds
        })
      });
      const data = await response.json();
      if (response.ok) {
        console.log(data.msg)
        this.notification.show("Student added successfully!", 2000, "good");
      } else {
        console.log("There was an error: " + data.msg);
        this.notification.show(data.msg, 2000, "bad");
      }
    } else {
      this.config.redirect("index");
    }
  }

  getSelectedSecondaryIds() {
    return this.secondaryListItems
      .filter(item => item.checkBox.checked)
      .map(item => item.course.id);
  }

  setPrimary(primary) {
    this.primary = primary;
  }

  open() {
    super.open();
    if (this.primary) {
      this.fillData();
    } else {
      this.clearData();
    }
  }

}

class ManagePage extends Page {
  constructor(role, primaryName, secondaryName) {
    if (!["admin", "mentor"].includes(role)) {
      console.log("Unknown role:", role)
    } else if (!["mentor", "course", "student"].includes(primaryName))  {
      console.log("Unknown primary:", primaryName)
    } else if (!["mentor", "course", "student"].includes(secondaryName)) {
      console.log("Unknown secondary:", secondaryName)
    } else {
      super(role);
      this.role = role
      this.primaryName = primaryName 
      this.secondaryName = secondaryName
      this.config = new Config();
      this.header = new Header(`Manage ${primaryName}s`, role);
      this.primaryListItems = [];
      this.selectedPrimary = null;
    }
  }

  async start() {
    this.getDomElements()
      .createModals()
      .activateButtons();
      await this.fetchPrimaries();
  }

  getDomElements() {
    this.primaryListArea = document.querySelector(".listmenu-list");
    this.addButton = document.querySelector(".listmenu-button.add");
    this.editButton = document.querySelector(".listmenu-button.edit");
    return this;
  }
    
  createModals() {
    this.managePrimary = new ManageModal(this.role, this.primaryName, this.secondaryName);
    this.managePrimary.setExitMethod(() => {
      this.closeModal(this.managePrimary);
    });
    return this;
  }
    
  activateButtons() {
    this.addButton.addEventListener("click", () => {
      this.selectedPrimary = null;
      this.openModal(this.managePrimary);
    });
    this.editButton.addEventListener("click", () => {
      if (this.selectedPrimary) {
        this.openModal(this.managePrimary);
      } else {
        this.notification.show(`No ${this.primaryName} selected!`, 2000);
      }
    });
    return this;
  }

  async fetchPrimaries() {
    const token = localStorage.getItem("token");
    const response = await fetch(`${window.API_BASE_URL}/api/${this.role}/${this.primaryName}list`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({"msg": `send ${this.primaryName}list`})
    });
        
    const data = await response.json();
    if (response.ok) {
      console.log(data)
      this.notification.show(`${this.primaryName} list loaded!`, 2000, "good");
      this.generatePrimaryList(data);
    } else {
      console.error(`Didn't get ${this.primaryName} data: ${data.msg}`);
      this.notification.show(`Didn't get ${this.primaryName} data!`, 2000, "bad");
    }
    return this;
  }

  generatePrimaryList(primaries) {
    removeChildNodes(this.primaryListArea);
    this.primaryListItems = [];
    for (let primary of primaries) {
      const listItem = this.createPrimaryListItem(primary);
      this.primaryListArea.appendChild(listItem.dom);
      this.primaryListItems.push(listItem);
    }
  }

  createPrimaryListItem(primary) {
    if (!primary.name) {
      primary.name = `${primary.first_name}, ${primary.last_name}`;
    }
    const template = document.createElement("template");
    template.innerHTML = 
      `<li class="listmenu-list-item">
        <label><input type="radio" name="${primary}" value="${primary.id}"> 
          ${primary.name}
        </label>
      </li>`.trim();
    const listItemDom = template.content.firstElementChild;
    const radio = listItemDom.firstElementChild.firstElementChild;
    radio.addEventListener("change", () => {
      this.selectedPrimary = primary;
    });
    return {
      primary,
      dom: listItemDom,
      radio: radio,
    }
  }

  disableInterface() {
    for (let item of this.primaryListItems) {
      item.radio.disabled = true;
      this.addButton.disabled = true;
      this.editButton.disabled = true;
    }
  }

  enableInterface() {
    for (let item of this.primaryListItems) {
      item.radio.disabled = false;
    }
    this.addButton.disabled = false;
    this.editButton.disabled = false;
  }

  openModal(modal) {
    modal.setPrimary(this.selectedPrimary);
    this.disableInterface();
    this.header.setTitle(modal.primary ? modal.title.edit : modal.title.add);
    modal.open();
  }

  closeModal(modal) {
    this.enableInterface();
    this.header.resetTitle();
    modal.close();
    this.fetchPrimaries(); // async
  }

}


