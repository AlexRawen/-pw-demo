import { LightningElement, api, track } from "lwc";
import { Option } from "./option";
import newLabel from "@salesforce/label/c.new";
export default class AdvCombobox extends LightningElement {
    @api label = "";
    @api options = [];
    @api name = "";
    @api value = null;
    @api button = {
        variant: "base",
        label: newLabel,
        title: newLabel,
        iconName: "utility:add",
        class: "slds-m-left_x-small",
    };
    @api disabled = false;
    @api placeholder = "Select an Option";
    @track isOpen = false;

    get advOptions() {
        return this.options.map((option, inx) => new Option(inx, option, this.value));
    }
    get containerCls() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? "slds-is-open" : ""}`;
    }
    get displayedValue() {
        if (this.value && this.options.length > 0) {
            const selected = this.options.filter(option => option.value === this.value);
            if (selected.length > 0) {
                return selected[0].label;
            }
        } else {
            return "";
        }
    }

    handleClickOption(evt) {
        const value = evt.currentTarget.getAttribute("data-value");
        this.isOpen = false;
        this.value = value;
        const cEvent = new CustomEvent("change", {
            detail: { value, name: this.name },
        });
        this.dispatchEvent(cEvent);
    }
    handleLeave() {
        this.isOpen = false;
    }
    handleClickButton() {
        this.isOpen = false;
        const cEvent = new CustomEvent("buttonclick", {
            detail: { name: this.name },
        });
        this.dispatchEvent(cEvent);
    }

    toggleOpen() {
        this.isOpen = this.disabled ? false : !this.isOpen;
    }
}
