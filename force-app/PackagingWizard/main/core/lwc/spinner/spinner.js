import { LightningElement, api } from "lwc";
import loading from "@salesforce/label/c.loading";

const TYPE_GLOBAL = "global";
const TYPE_LOCAL = "local";

export default class Spinner extends LightningElement {
    @api text = "";
    @api isShown = false;
    @api type = TYPE_GLOBAL;
    labels = { loading };
    get isGlobal() {
        return this.type === TYPE_GLOBAL;
    }

    get cssClass() {
        return ["slds-spinner_container", this.isGlobal ? "slds-is-fixed" : "slds-is-absolute"].join(" ");
    }

    connectedCallback() {
        if (this.isGlobal) {
            window.addEventListener("ShowSpinnerEvent", this.onShowSpinnerEvent.bind(this));
        }
    }

    onShowSpinnerEvent(event) {
        this.text = event.detail.text;
        this.isShown = !!event.detail.isShown;
    }
}
