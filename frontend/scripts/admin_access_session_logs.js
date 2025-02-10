class AdminAccessSessionLogs extends AdminAccess {

    constructor() {
        super("Mentor session logs");
    }

    start() {
        super.start();
        console.log("hooray session logs");
    }
}

new AdminAccessSessionLogs();