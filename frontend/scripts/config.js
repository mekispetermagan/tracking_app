window.API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5000'  // development
    : 'https://afterschoolgeekery.org';  // production

const baseURL = window.location.hostname === 'localhost'
    ? 'http://localhost:10001' // development
    : 'https://afterschoolgeekery.org/tracking';  // production

const redirect = (path) => {
    window.location.href = `${baseURL}/${path}.html`; 
}

class Config {
    constructor() {
    window.API_BASE_URL = window.location.hostname === 'localhost' 
        ? 'http://localhost:5000'  // development
        : 'https://afterschoolgeekery.org';  // production

    this.baseURL = window.location.hostname === 'localhost'
        ? 'http://localhost:10001' // development
        : 'https://afterschoolgeekery.org/tracking';  // production
    }

    redirect(filename) {
        window.location.href = `${this.baseURL}/${filename}.html`; 
    }

    redirectWithParameters(filename, parameters) {
        const urlParameters = Object.keys(parameters)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(parameters[key])}`)
            .join("&");
        window.location.href = `${filename}.html?${urlParameters}`;
    }
}
