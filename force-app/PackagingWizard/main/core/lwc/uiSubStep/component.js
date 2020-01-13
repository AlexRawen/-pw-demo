export class Component {
    get hasLoader() {
        return !!this.loader && this.loading;
    }
    get isCombobox() {
        return this.type === "combobox";
    }
    get isHelptext() {
        return this.type === "helptext";
    }
    get isAdvCombobox() {
        return this.type === "advcombobox";
    }
    get isButton() {
        return this.type === "button";
    }
    get isInput() {
        return this.type === "input";
    }
    constructor(id, {type, props, loader}, loading) {
        this.id = id;
        this.type = type;
        this.props = props;
        this.loader = loader || null;
        this.loading = loading;
    }
}