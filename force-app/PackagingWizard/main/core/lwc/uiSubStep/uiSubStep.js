import BaseService from "c/baseService";
import { api, track } from "lwc";
import { Component } from "./component";

export default class UiSubStep extends BaseService {
    @api valid = false;
    @api stepByStep = false;
    @api active = false;
    @api title;
    @api name = "";
    @api description;
    @api components = [];
    @api rightButton = null;
    @api rightText = null;
    @api loading = false;
    @api substepRerender = false;

    get rightTextIsText() {
        return !this.rightText || typeof this.rightText === 'string';
    }
    get liStyleClass() {
        let res = "slds-progress__item";
        if (this.stepByStep) {
            if (this.active && !this.valid) {
                res += " slds-is-active";
            } else if (!this.active && !this.valid) {
                res += " slds-is-disabled";
            }
        }
        return res;
    }
    get rightTextCls() {
        return `substep__right-text slds-text-align_right slds-text-color_weak ${this.hasRightButton ? "slds-p-top_medium" : ""}`;
    }
    get advComponents() {
        return this.components.map((cmp, id) => new Component(id, cmp, this.loading));
    }
    get advRightButton() {
        if (this.hasRightButton) {
            return new Component("rightButton", this.rightButton, this.loading);
        } else {
            return null;
        }
    }
    get hasRightButton() {
        return !!this.rightButton;
    }
    get hasRightText() {
        return this.rightText !== null;
    }
    get hasDescription() {
        return !!this.description;
    }
    handleRightButtonClick() {
        BaseService.pushEvent("rbuttonclick", { step: this.name }, this);
    }
    handleChangeComponentValue(evt) {
        const el = evt.currentTarget;
        evt.stopPropagation();
        evt.preventDefault();
        const name = el.getAttribute("data-name");
        const value = el.value;
        BaseService.pushEvent("change", { name, value, step: this.name }, this);
    }
    handleButtonClick(evt) {
        const el = evt.currentTarget;
        evt.stopPropagation();
        const name = el.getAttribute("data-name");
        BaseService.pushEvent("buttonclick", { name, step: this.name }, this);
    }
}
