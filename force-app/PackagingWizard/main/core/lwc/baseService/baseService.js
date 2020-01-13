import { LightningElement } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

const SEVERITY_ERROR = "error";
const EVENTS_NAME = {
    spinner: "ShowSpinnerEvent",
    modal: "ShowModalEvent",
};

export default class BaseService extends LightningElement {
    static invokeServiceMethod(action, parameters) {
        return new Promise((resolve, reject) => {
            const requestStr = JSON.stringify(parameters);
            action({ request: requestStr })
                .then(result => {
                    if (result.status === SEVERITY_ERROR) {
                        reject(result.messages);
                    }
                    const returnValue = result && result.data;
                    resolve(returnValue);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }
    static invokeServiceMethodWithoutParameters(action) {
        return new Promise((resolve, reject) => {
            action()
                .then(result => {
                    if (result.status === SEVERITY_ERROR) {
                        reject(result.messages);
                    }
                    const returnValue = result && result.data;
                    resolve(returnValue);
                })
                .catch(error => {
                    reject(error);
                });
        });
    }
    static pushEvent(name, detail, target) {
        target = target || this;
        const cEvent = new CustomEvent(name, {
            detail,
        });
        target.dispatchEvent(cEvent);
    }
    static showSpinner(isShown, text = "") {
        BaseService.pushEvent(EVENTS_NAME.spinner, { text, isShown }, window);
    }
    static showModal(title, message, footer, callback, directional) {
        BaseService.pushEvent(
            EVENTS_NAME.modal,
            {
                title,
                message,
                callback,
                footer,
                directional,
            },
            window
        );
    }
    static lightningValidate(selector) {
        return [...selector].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    }
    static getUrlParameter(name) {
        name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        const regex = new RegExp("[\\?&]" + name + "=([^&#]*)");
        const results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
    }
    static showToast(message, title="Something goes wrong!", variant="error") {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        window.dispatchEvent(event);
    }
    static handleExceptions(error, errorMessage) {
        console.error(error);
        const errorsArray = error && Array.isArray(error) ? error : [];

        errorsArray.forEach(err => {
            BaseService.showToast(err.message, errorMessage, err.severity);
        });
    }
}