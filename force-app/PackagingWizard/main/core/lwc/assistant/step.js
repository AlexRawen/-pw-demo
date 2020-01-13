export default class Step {
    constructor(name, title, description, value, openable = false, disabled = false) {
        this.title = title || "";
        this.description = description || "";
        this.inx = value || 1;
        this.openable = openable;
        this.name = name || this.inx;
        this.valid = false;
        this.disabled = disabled;
        this.progress = 0;
    }
    disable(val) {
        this.disabled = val;
    }
}
