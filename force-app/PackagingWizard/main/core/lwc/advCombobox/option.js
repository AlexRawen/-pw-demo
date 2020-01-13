export class Option {
    get isSelected() {
        return  this.value === this.selectedValue;
    }
    get optionId() {
        return `option-${id}`;
    }
    constructor(id, {label, value}, selectedValue) {
        this.id = id;
        this.label = label;
        this.value = value;
        this.selectedValue = selectedValue;
    }
}