import { track } from "lwc";
import BaseService from "c/baseService";
import { Button } from "./button";
import { labels } from "./labels";

const BUTTON_NAME_OK = "ok";
const INPUTS_SELECTOR = "lightning-input, lightning-combobox, lightning-textarea";
export default class SfConnect extends BaseService {
    @track isOpen = false;
    @track title;
    @track footer;
    @track directional = false;
    @track showCheckbox = true;
    @track clear = false;
    labels = labels;
    callback;
    get modalCls() {
        return `slds-modal${this.isOpen ? " slds-fade-in-open" : ""}`;
    }
    get backdropCls() {
        return `slds-backdrop${this.isOpen ? " slds-backdrop_open" : ""}`;
    }
    get headerCls() {
        return `slds-modal__header${!this.hasHeader ? " slds-modal__header_empty" : ""}`;
    }
    get footerCls() {
        return `slds-modal__footer${this.directional ? " slds-modal__footer_directional" : ""}`;
    }
    get hasHeader() {
        return !!this.title;
    }
    get hasFooter() {
        return !!this.footer && this.footer.length > 0;
    }
    closeForm(noEvent) {
        if (noEvent !== true && this.callback) {
            try {
                this.callback({ action: "close" });
            } catch (e) {
                console.warn(e);
            }
        }
        this.isOpen = false;
    }
    checkMessageInputs() {
        return BaseService.lightningValidate(this.template.querySelectorAll(INPUTS_SELECTOR));
    }
    messageInputsValue() {
        let res = {};
        [...this.template.querySelectorAll(INPUTS_SELECTOR)].forEach(input => {
            res[input.getAttribute("data-name")] =
                input.getAttribute("data-type") !== "checkbox" ? input.value : input.checked;
        });
        return res;
    }
    handleFooterClick(evt) {
        try {
            const btnName = evt.target.name;
            const btnVal = evt.target.value;
            if ((btnName === BUTTON_NAME_OK && this.checkMessageInputs()) || btnName !== BUTTON_NAME_OK) {
                const returnValue = Object.assign(
                    { action: btnName },
                    btnName === BUTTON_NAME_OK ? this.messageInputsValue() : {}
                );
                if (!!this.footer[btnVal].callback) {
                    this.footer[btnVal].callback(returnValue);
                } else if (!!this.callback) {
                    this.callback(returnValue);
                }
                this.closeForm(true);
            }
        } catch (e) {
            console.warn(e);
        }
    }
    onShowModalEvent({ detail = { title, callback, directional, showCheckbox, clear } }) {
        try {
            this.title = detail.title;
            this.directional = detail.directional;
            if (detail.footer && Array.isArray(detail.footer)) {
                this.footer = detail.footer.map((btn, inx) => new Button(btn, inx));
            } else {
                this.footer = [];
            }
            this.showCheckbox = detail.showCheckbox;
            this.isOpen = true;
            this.callback = detail.callback;
            if (detail.clear) {
                this.clear = true;
                setTimeout(() => {
                    this.clear = false;
                }, 100);
            }
        } catch (e) {
            console.error("Wrong event details for modal!", e);
        }
    }
    constructor() {
        super();
        window.addEventListener("showSFConnectEvent", this.onShowModalEvent.bind(this));
    }
}
