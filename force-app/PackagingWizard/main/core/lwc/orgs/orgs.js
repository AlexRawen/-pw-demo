import { api, track } from "lwc";
import BaseService from "c/baseService";
import { SubStep } from "c/srvSubStep";
import { stepsStruct } from "./stepsStruct";
import authorizeOrg from "@salesforce/apex/SfOrgsCrtl.authorizeOrg";
import revokeOrgAuthorization from "@salesforce/apex/SfOrgsCrtl.revokeOrgAuthorization";
import getAuthorizationsInfo from "@salesforce/apex/SfOrgsCrtl.getAuthorizationsInfo";
import getLinkedNamespaces from "@salesforce/apex/SfOrgsCrtl.getLinkedNamespaces";
import getPackageName from "@salesforce/apex/SfOrgsCrtl.getPackageName";
import getManagedPackagePrefix from "@salesforce/apex/SfOrgsCrtl.getManagedPackagePrefix";
import selectManagedPackagePrefix from "@salesforce/apex/SfOrgsCrtl.selectManagedPackagePrefix";
import setPackageName from "@salesforce/apex/SfOrgsCrtl.setPackageName";
import { labels } from "./labels";
import { errorMessages } from "c/errorMessages";

const NAMESPACE_REGISTRY_URL = "/lightning/o/NamespaceRegistry/list";
export default class Orgs extends BaseService {
    @api inx = 1;
    @api title = "";
    @api desc = "";
    @api name = "";
    @api disabled = false;
    @track loading = true;
    @track isOpen = true;
    @track progress = 0;
    @track packageName = "";
    @track nameSpaces = [];
    @track prefix = "";
    @track substeps = [];
    @track substepRerender = false;
    @track nameSpace = null;

    stepByStep = false;
    labels = labels;

    get itemCls() {
        return `slds-setup-assistant__item ${
            this.disabled ? "slds-scoped-notification_light slds-theme--alert-texture" : ""
        }`;
    }
    get valid() {
        return this.progress === 100;
    }
    get detailCls() {
        return `slds-summary-detail${this.isOpen ? " slds-is-open" : ""}`;
    }
    get nameSpacesOptions() {
        return this.nameSpaces.map(item => {
            return { value: item, label: item };
        });
    }

    handleOpen() {
        if (!this.disabled) {
            this.isOpen = !this.isOpen;
        }
    }
    async confirmRevoke(org) {
        return await new Promise(resolve =>
            BaseService.showModal(
                null,
                `<h2 class="slds-text-heading_small">${labels.areYouSure}</h2>`,
                [
                    {
                        label: labels.cancel,
                        variant: "neutral",
                        callback: () => {
                            resolve(false);
                        },
                    },
                    {
                        variant: "brand",
                        label: labels.yes,
                        callback: () => {
                            resolve(true);
                        },
                    },
                ],
                () => {
                    resolve(false);
                }
            )
        );
    }
    subStepByName(name) {
        const org = this.substeps.filter(item => item.name === name);
        return org.length > 0 ? org[0] : null;
    }
    cmpByName(subStepName, cmpName) {
        let res = null;
        if (typeof subStepName === "string") {
            subStepName = this.subStepByName(subStepName);
        }
        try {
            res = subStepName.components.filter(cmp => cmp.props.name === cmpName)[0];
        } catch (e) {
            console.warn(e);
        }
        return res;
    }
    sendUpdateInfo() {
        BaseService.pushEvent(
            "changeprogress",
            {
                progress: this.progress,
                name: this.name,
                valid: this.valid,
                subs: this.substeps.reduce((obj, item) => ((obj[item.name] = item.valid), obj), {}),
            },
            this
        );
    }
    doSubRerender() {
        this.substepRerender = !this.substepRerender;
        this.sendUpdateInfo();
    }
    calcProc() {
        const len = this.substeps.length;
        const valids = this.substeps.filter(item => item.valid).length;
        if (len > 0) {
            this.progress = Math.ceil((valids * 100) / len);
            this.doSubRerender();
        }
    }
    handleChangeValue({ detail }) {
        switch (detail.step) {
            case "package":
                const packageStep = this.subStepByName(detail.step);
                this.cmpByName(packageStep, detail.name).props.value = detail.value;
                if (
                    this.packageName !== this.cmpByName(packageStep, "name").props.value ||
                    this.prefix !== this.cmpByName(packageStep, "prefix").props.value
                ) {
                    packageStep.changeState("unsaved");
                } else {
                    packageStep.changeState("default");
                }
                this.calcProc();
                break;
            default:
                console.error("Unexpected step", detail.step, detail);
                break;
        }
    }
    handleButtonClick({ detail }) {
        switch (detail.step) {
            case "package":
                this.handleNameSpaceRegistryClick();
                break;
            default:
                console.error("Unexpected step", detail.step, detail);
                break;
        }
    }
    async handleRightButtonClick({ detail }) {
        switch (detail.step) {
            case "package":
                this.handleSavePackageSettings();
                break;
            default:
                this.handleConnectClick(detail.step);
                break;
        }
    }

    revokeToken(org) {
        BaseService.invokeServiceMethod(revokeOrgAuthorization, { orgName: org.name })
            .then(() => {
                org.valid = false;
                org.userName = "";
                this.calcProc();
            })
            .catch(e => {
                console.error(e);
                e.forEach(error => {
                    BaseService.showToast(error.message, null, error.severity);
                });
            });
    }
    getOrgsCtrlVal(method, parameter, as) {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethodWithoutParameters(method)
                .then(res => {
                    let obj = {};
                    obj[as] = res[parameter] || null;
                    resolve(obj);
                })
                .catch(err => {
                    BaseService.handleExceptions(err, errorMessages.orgs.orgInfo);
                    reject(err);
                });
        });
    }
    setNameVal(method, value) {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethod(method, { name: value })
                .then(() => {
                    resolve();
                })
                .catch(err => {
                    BaseService.handleExceptions(err, errorMessages.orgs.packageSettings);
                    reject(err);
                });
        });
    }
    getAuthorizationsInfo() {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethodWithoutParameters(getAuthorizationsInfo)
                .then(res => {
                    for (let key in res) {
                        const org = this.subStepByName(key);
                        if (org) {
                            org.valid = res[key].isAuthorized != null ? res[key].isAuthorized : false;
                            org.userName = res[key].userName != null ? res[key].userName : "";
                        }
                    }
                    this.calcProc();
                    resolve({});
                })
                .catch(err => {
                    BaseService.handleExceptions(err, errorMessages.orgs.authInfo);
                    reject(err);
                });
        });
    }
    async openLoginForm(title, name, clear) {
        return await new Promise((resolve, reject) =>
            BaseService.pushEvent(
                "showSFConnectEvent",
                {
                    title,
                    footer: [
                        {
                            label: labels.cancel,
                            name: "cancel",
                            callback: () => {
                                reject(false);
                            },
                        },
                        {
                            label: labels.connect,
                            variant: "brand",
                            name: "ok",
                            callback: res => {
                                delete res.action;
                                if (!res.isSandbox) {
                                    res.isSandbox = false;
                                }
                                resolve(res);
                            },
                        },
                    ],
                    showCheckbox: name !== "devhub",
                    callback: () => {
                        reject(false);
                    },
                    clear,
                },
                window
            )
        );
    }
    startLoginToSF(org, clear = true) {
        this.openLoginForm(`${labels.connectTo} ${org.title}`, org.name, clear).then(res => {
            BaseService.showSpinner(true, labels.connectToSF);
            res.orgName = org.name;
            BaseService.invokeServiceMethod(authorizeOrg, res)
                .then(() => {
                    this.getAuthorizationsInfo()
                        .catch(err => {
                            BaseService.handleExceptions(err, errorMessages.orgs.authorization);
                        })
                        .finally(() => {
                            BaseService.showSpinner(false);
                        });
                })
                .catch(err => {
                    BaseService.handleExceptions(err, errorMessages.orgs.connection);
                    this.startLoginToSF(org, false);
                })
                .finally(() => {
                    BaseService.showSpinner(false);
                });
        });
    }
    async handleConnectClick(orgName) {
        const org = this.subStepByName(orgName);
        if (org) {
            if (org.valid) {
                if (await this.confirmRevoke(org)) {
                    this.revokeToken(org);
                }
            } else {
                this.startLoginToSF(org);
            }
        }
    }
    handleNameSpaceRegistryClick() {
        document.location.href = NAMESPACE_REGISTRY_URL;
    }

    async handleSavePackageSettings() {
        const packageStep = this.subStepByName("package");
        BaseService.showSpinner(true, labels.saving);
        const vals = {
            prefix: { api: selectManagedPackagePrefix, value: this.cmpByName(packageStep, "prefix").props.value },
            name: { api: setPackageName, value: this.cmpByName(packageStep, "name").props.value },
        };
        try {
            await BaseService.invokeServiceMethod(vals.prefix.api, { name: vals.prefix.value });
            await BaseService.invokeServiceMethod(vals.name.api, { name: vals.name.value });
            packageStep.valid = true;
            this.nameSpace = vals.prefix.value;
            this.packageName = vals.name.value;
            packageStep.changeState("default");
            this.calcProc();
            BaseService.showToast(null, labels.saveSuccess, "success");
        } catch (err) {
            BaseService.handleExceptions(err, errorMessages.orgs.savePackage);
        } finally {
            BaseService.showSpinner(false);
        }
    }
    connectedCallback() {
        Promise.all([
            this.getAuthorizationsInfo(),
            this.getOrgsCtrlVal(getLinkedNamespaces, "namespaces", "nameSpaces"),
            this.getOrgsCtrlVal(getPackageName, "name", "packageName"),
            this.getOrgsCtrlVal(getManagedPackagePrefix, "name", "prefix"),
        ])
            .then(res => Object.assign({}, ...res))
            .then(res => {
                this.nameSpaces = res.nameSpaces || [];
                this.packageName = res.packageName || "";
                this.prefix = res.prefix || "";
                const packageStep = this.subStepByName("package");
                packageStep.valid = this.subStepByName("package").valid =
                    this.packageName.length > 0 && this.prefix.length > 0;
                this.cmpByName(packageStep, "name").props.value = this.packageName;
                this.cmpByName(packageStep, "prefix").props.options = this.nameSpacesOptions;
                this.cmpByName(packageStep, "prefix").props.value = this.prefix;
                this.calcProc();
            })
            .finally(() => {
                this.loading = false;
            });
    }
    constructor() {
        super();
        this.substeps = stepsStruct.map((item, inx) => new SubStep(inx, item));
    }
}
