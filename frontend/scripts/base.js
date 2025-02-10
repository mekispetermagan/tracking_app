/*
    Base classes for the admin interface
    ====================================

    Header: creates a header for pages. Instantiated in each page.
      Elements:
        - home button: redirects to a specified home HTML
        - title: title of the page
        - logout button: redirects to index.html, where token is deleted
      Parameters:
        - title (string): title of the header
        - home (string): file name without the ".html" extension
      Public methods:
        - setTitle(title: string): updates the header title
        - setHome(home: string): updates the home link for redirection

    Notification: creates a notification div for pages. It is fixed to the
      top right and hidden by default.
      Methods:
      - show(message: string, timeout: number, quality: "good" | "bad" | "other"): shows notification.
        - message: notification content, possibly HTML
        - quality: background color of notification
          - good: green background
          - bad: red background
          - other: gray background (default)
        - timeout: duration in seconds; optional, defaults to infinite (no hiding)
      - hide(): use to manually hide the notification if no timeout is given

    Page: A parent class for pages. Page content is hidden until successful
      validation. Upon success, content is shown, and page starts with
      a specified callback function.

    AdminPage: Page with admin authentication.

    MentorPage: Page with mentor authentication.

    Modal: Popup interface on a page.

    LanguageMenu: Lets the user choose between languages;
      connected to the page's language setting mechanism.

    Form:

    Filter:
*/


// A header bar over pages. It contains
// - a home button that redirects to the page provided as a parameter
// - a title provided as a parameter (and possibly modified by the
//   language menu or a modal)
// - a logout button that redirects to the login page (which logs the
//   user out)
class Header {
    constructor(title, home) {
        this.config = new Config();
        this.container = document.querySelector("header") || this.createHeader();
        this.originalTitle = title;
        this.setLink()
            .setHTML()
            .getDomElements()
            .setTitle(title)
            .setHome(home)
            .setLogout();
    }

    createHeader() {
        const header = document.createElement("header");
        document.body.insertAdjacentElement("afterbegin", header);
        return header;
    }

    // adds the material symbols link needed to display icons
    setLink() {
        if (!document.querySelector('link[href*="Material+Symbols+Outlined"]')) {
            document.head.insertAdjacentHTML("beforeend", `
                <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=home,logout" />
            `);
        }
        return this;
    }

    // creates the content of the header, and inserts it in the page
    setHTML() {
        this.container.insertAdjacentHTML(
            "beforeend",
            `<button class="navigation-button" id="nav-home">
                <div class="material-symbols-outlined">home</div>
            </button>
            <h2 class="page-title"></h2>
            <button class="navigation-button" id="nav-logout">
                <div class="material-symbols-outlined">logout</div>
            </button>`.trim()
            );
        return this;
    }

    getDomElements() {
        this.titleArea = this.container.querySelector("h2");
        this.homeButton = this.container.querySelector("#nav-home");
        this.logoutButton = this.container.querySelector("#nav-logout");
        return this;
    }

    setTitle(title) {
        this.titleArea.innerHTML = title;
        return this;
    }

    resetTitle() {
        this.setTitle(this.originalTitle);
    }

    setHome(home) {
        this.homeButton.addEventListener("click", () => {
            this.config.redirect(home);
        })
        return this;
    }

    setLogout() {
        this.logoutButton.addEventListener("click", () => {
            this.config.redirect("index");
        })
        return this;
    }
} // Header

class Notification {
    constructor () {
        this.dom = document.createElement("div");
        document.body.appendChild(this.dom);
        this.resetClasses();
        this.timer = new Timer();
    }

    resetClasses() {
        this.dom.className = "notification";
    }

    hide() {
        this.resetClasses();
    }

    show(message, duration, quality) {
        this.resetClasses();
        this.dom.classList.add("active");
        this.dom.classList.add(quality);
        this.dom.innerHTML = message;
        if (Number.isFinite(duration) && duration >= 0) {
            this.timer.delay(() => {this.hide();}, duration);
        }
    }

    good(message) {
        this.show(message, 3000, "good");
    }

    bad(message) {
        this.show(message, 3000, "bad");
    }

} // Notification

// A general Page class. Individual pages should be subclasses
// of this one. It provides:
// - config         (see config.js)
// - timer          (see utils.js)
// - notification   (see above)
// objects. No functionality implemented here.
class Page {
    config = new Config();
    timer = new Timer();
    notification = new Notification();
    container = document.querySelector(".page-content");

    constructor() {
    }

    hideContent() {
        this.container.classList.remove("active");
        this.container.classList.add("inactive");
    }

    showContent() {
        this.container.classList.remove("inactive");
        this.container.classList.add("active");
    }
} // Page

// Page with role-based user validation.
// Page content is not visible until successful validation. If
// validation is unsuccessful, user is logged out.
// Preferred language provides an option for localizing the content.
class AuthPage extends Page {
    preferredLanguage = "en";

    constructor(role) {
        super();
        this.hideContent();
        this.validate(role);
    }

    async validate(role) {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api/auth/validate/${role}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({})
            });

            const data = await response.json();
            if (response.ok) {
                if (data.preferred_language) {
                    this.preferredLanguage = data.preferred_language;
                    console.log("preferred language:", this.preferredLanguage);
                }
                this.showContent();
                this.start();
                console.log("Authorization successful.");
                this.notification.good("Authorization successful!");
            } else {
                console.error("Authorization failed:", data.msg);
                this.notification.bad("Authorization failed.");
                this.backToLogin();
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
            this.backToLogin();
        }
    }

    // This is where the page starts after validation
    start() {}

    // Failed validation: redrected to the login page.
    backToLogin() {
        this.timer.delay(() => {
            this.config.redirect("index");
        }, 3000);
    }
} // AuthPage

// Admin pages have a header with the page title, redirecting to the admin base.
class AdminPage extends AuthPage {
    constructor(title) {
        super("admin");
        this.header = new Header(title, "admin");
    }
} // AdminPage

// Mentor pages have a header with the page title, redirecting to the mentor base.
// Mentor pages are localized. Preferred language is decided after validation.
class MentorPage extends AuthPage {
    constructor(title) {
        super("mentor");
        this.header = new Header(title, "mentor");
        this.languageMenu = new LanguageMenu((lang) => {
            this.setLanguage(lang);
        });
    }

    start() {
        this.getDomElements();
        this.setLanguage(this.preferredLanguage);
    }

    getDomElements() {
        this.languageTexts = document.querySelectorAll(".language-content");
    }

    setLanguage(lang) {
        this.language = lang;
        this.languageTexts.forEach(item => item.innerHTML = languageData[lang][item.dataset.key]);
        this.languageMenu.adjustMenu(lang);
    }
} // MentorPage

class Modal {
    constructor (overlay) {
        this.overlay = overlay;
        this.modal = overlay.querySelector(".modal");
        this.notification = new Notification();
        this.config = new Config();
        this.timer = new Timer();
        this.exit = () => {};
        window.addEventListener("keydown", (e) => {
            if (e.key == "Escape") {
                this.exit();
            }
        });

    }

    open() {
        this.overlay.style.display = "flex";
    }

    close() {
        this.overlay.style.display = "none";
    }

    setExitMethod(fn) {
        this.exit = fn;
    }
} // Modal

class LanguageMenu {
    constructor(setLanguage) {
        this.setLanguage = setLanguage;
        this.container = document.querySelector(".language-menu");
        this.createHTML()
            .activate();
    }

    createHTML() {
        this.container.innerHTML =
            `<div class="language-menu">
            <div class="language-option">
                <input type="radio" id="lang-en" name="language" value="en" checked>
                <label for="lang-en">EN</label>
            </div>
            <div class="language-option">
                <input type="radio" id="lang-hu" name="language" value="hu">
                <label for="lang-hu">HU</label>
            </div>
            <div class="language-option">
                <input type="radio" id="lang-ua" name="language" value="ua">
                <label for="lang-ua">UA</label>
            </div>
        </div>`.trim();
        return this;
    }

    activate() {
        for (let lang of ["en", "hu", "ua"]) {
            this[lang] = this.container.querySelector(`#lang-${lang}`);
            this[lang].addEventListener("change", () => {
                this.setLanguage(lang);
            });
        }
    }

    adjustMenu(lang) {
        this[lang].checked = true;
    }
} // LanguageMenu

// Manages forms on pages:
// Collects input fields
// Prefills them with data (from server or from frontend)
// Submits form data to server
// Uses the first form element in its container. If container is
// not provided, it defaults to document.
// container:
// - if the page contains a single form, it can be this.content
// - otherwise a more specific dom element
// submitEndpoint:
// - full route, eg. "/mentor/submit_photos"
class Form {
    formName = "Form";
    exit = null;
    hasFiles = false;
    forwardData = null;

    constructor(container, submitEndpoint) {
        if (!container) {
            container = document;
        }
        this.form = container.querySelector("form");
        this.submitEndpoint = submitEndpoint;
        this.timer = new Timer();
        this.config = new Config();
        this.backToLogin = () => this.timer.delay(() => {this.config.redirect("index");}, 3000);
        this.getInputs();
    }

    getInputs() {
        this.inputs = [...this.form.querySelectorAll("input, select")];
        this.form.addEventListener("submit", (e) => {
            e.preventDefault();
            this.submitData(this.collectFormData());
        });
    }

    // name used in notifications
    setFormName(formName) {
        this.formName = formName;
    }

    // inherit the notification object of its page
    setNotification(notification) {
        this.notification = notification;
    }

    // exit function: exit after submission (specified in the page)
    setExitFunction(exit) {
        this.exit = exit;
        this.cancelButton = this.form.querySelector("button.cancel");
        if (this.cancelButton) {
            this.cancelButton.addEventListener("click", exit);
        }
    }

    // forwards the received data to the specified function
    setForwardData(callBack) {
        this.forwardData = callBack;
    }

    // the page's notification object (displays messages to the user)
    setNotification(notification) {
        this.notification = notification;
    }

    // logs out the user. normally the default should work,
    // but it can be overwritten here
    setBackToLogin(backToLogin) {
        this.backToLogin = backToLogin;
    }

    setSubmitEndpoint(endpoint) {
        this.submitEndpoint = endpoint;
    }

    clear() {
        this.inputs.forEach((input) => {
            if (["text", "email"].includes(input.type)) {
                input.value = "";
            } else if (["radio", "checkbox"].includes(input.type)) {
                input.checked = false;
            }
        })
    }

    fillWith(data) {
        this.inputs.forEach((input) => {
            const name = input.name;
            const value = data[name];
            if (!data[name]) {
                console.log(name, "not filled.");
            } else if (["radio", "checkbox"].includes(input.type)) {
                input.checked = true;
                console.log(name, "set to", data[name]);
            } else if (["text", "email", "number"].includes(input.type)) {
                input.value = value;
                console.log(name, "set to", data[name])
            } else if (input.type == "date") {
                input.valueAsDate = data[name];
                console.log("Date set to", data[name]);
            }else if (input.tagName.toLowerCase() == "select") {
                input.value = data[name];
                console.log(name, "set to", data[name]);
            } else {
                console.log(name, "not handled");
            }
        });
    }

    fillField(name, value) {
        const inputElement = this.form.querySelector(`input[name=${name}]`);
        if (inputElement) {
            inputElement.value = value;
            console.log(`${name} set to ${value}`);
        } else {
            console.log(`${name} not found`)
        }
    }

    async fetchPrefillData(prefillEndpoint) {
        const token = localStorage.getItem("token");
        if (token) {
            const response = await fetch(`${window.API_BASE_URL}/api${prefillEndpoint}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({"msg": "Send prefill data"})
            });

            const data = await response.json();
            if (response.ok) {
                console.log(`Prefill data received.`);
                this.fillWith(data);
            } else {
                console.error(`${this.formName} prefill data not received:`, data.msg);
            }
        } else {
            console.error("No token found.");
            this.notification.bad("Logged out.");
            this.backToLogin();
        }
    }

    collectFormData() {
        this.hasFiles = false;
        const formData = new FormData(this.form);
        this.inputs.forEach((item) => {
            if (item.type == "file") {
                [...item.files].forEach((file) => {
                    formData.append(`${item.name}-file`, file);
                    this.hasFiles = true;
                })
            }
        });
        return formData;
    }

    async submitData(formData) {
        console.log(formData)
        const token = localStorage.getItem("token");
        let headers, body;
        if (this.hasFiles) {
            headers = {
                'Authorization': `Bearer ${token}`
            }
            body = formData;
        } else {
            headers = {
                'Content-Type': "application/json",
                'Authorization': `Bearer ${token}`
            }
            const formDataObj = Object.fromEntries(formData.entries());
            body = JSON.stringify(formDataObj)
        }
        if (token) {
            const formDataObj = Object.fromEntries(formData.entries());
            const response = await fetch(`${window.API_BASE_URL}/api${this.submitEndpoint}`, {
                method: 'POST',
                headers: headers,
                body: body
            });

            const data = await response.json();
            if (response.ok) {
                console.log(`${this.formName} submitted successfully.`);
                if (this.notification) {
                    this.notification.good(
                        `${this.formName} submitted successfully.`
                    );
                }
                if (this.exit) {
                    this.timer.delay(() => {this.exit();}, 1000);
                } else if (this.forwardData) {
                    this.forwardData(data);
                }
            } else {
                console.error(`${this.formName} couldn't be submitted:`, data.msg);
                if (this.notification) {
                    this.notification.bad("Submission failed.");
                }
            }
        } else {
            console.error("No token found.");
            if (this.notification) {
                this.notification.bad("Logged out.");
            }
            this.backToLogin();
        }
    }
} // Form


// Filters an object-list with checkboxes and radiobuttons.
// The filtering is instant when any change happens in these inputs.
// The owner (say, Page or Modal) provides a callback function,
// and provides the list to be filtered; which is then returned.
// (The objectlist cannot be provided at construction,
// because it may change dynamically.)
// Template for the owner:
// class FilterOwner {
//     constructor() {
//         this.filterContainer = ...;
//         this.objectList = ...;
//         // create a Filters object with callback:
//         this.filters = new Filters(this.filterContainer, this.updateFilteredList.bind(this));
//     }
//
//     updateFilteredList() {
//         // Delegate the filtering to Filters
//         const filteredObjectList = this.filters.filterList(this.objectList);
//         ... // Handle filtered list
// }

class Filters {
    constructor(container, onFilterChange) {
        this.form = container;
        this.inputs = [...this.form.querySelectorAll(
            "input[type='radio'], input[type='checkbox']"
        )];
        this.inputs.forEach(
            item => {
                item.checked = false;
                if (item.type=="checkbox") {
                    item.addEventListener("change", onFilterChange);
                } else {
                    item.addEventListener("change", (e) => {
                        e.stopImmediatePropagation(); // disable the event
                    });
                    item.addEventListener("click", (e) => {
                        e.preventDefault();
                        setTimeout(() => {
                            if (item.checked) {
                                item.checked = false;
                            } else {
                                item.checked = true;
                            }
                            onFilterChange();
                        }, 0);
                    });
                }
            }
        );
    }

    filterList(objectList) {
        const formData = new FormData(this.form);
        const filterValues = Object.fromEntries(formData.entries());
        console.log("inputs:", this.inputs)
        console.log("filtervalues:", filterValues)
        return objectList.filter(obj =>
            Object.keys(filterValues).every(key =>
            {
                console.log(key, filterValues[key], obj[key])
                return filterValues[key] == obj[key].toString()
            }
            )
        );
    }

    disable() {
        this.inputs.forEach(item => item.disabled = true);
    }

    enable() {
        this.inputs.forEach(item => item.disabled = false);
    }
}
