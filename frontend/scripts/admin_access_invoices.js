class AdminAccessInvoices extends AdminAccess {
    constructor() {
        super("Mentor invoices");
    }

    start() {
        super.start();
        console.log("hooray invoices");
        this.form.setSubmitEndpoint("/admin/get_invoice");
        this.form.setForwardData(this.displayInvoice);
    }

    displayInvoce(data) {
        console.log("invoice:", data);
    }
}

new AdminAccessInvoices();