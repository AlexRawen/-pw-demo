import BaseService from "c/baseService";
import { api, track } from "lwc";
import getAuthorizationInfo from "@salesforce/apex/HerokuCmpCtrl.getAuthorizationInfo";
import getOAuthUrl from "@salesforce/apex/HerokuCmpCtrl.getOAuthUrl";
import getConnectGitHubUrl from "@salesforce/apex/HerokuCmpCtrl.getConnectGitHubUrl";
import exchangeCodeForAccessToken from "@salesforce/apex/HerokuCmpCtrl.exchangeCodeForAccessToken";
import revokeAccessToken from "@salesforce/apex/HerokuCmpCtrl.revokeAccessToken";
import getAppsAndPipelineInfo from "@salesforce/apex/HerokuCmpCtrl.getAppsAndPipelineInfo";
import createAppsAndPipeline from "@salesforce/apex/HerokuCmpCtrl.createAppsAndPipeline";
import removeAppsAndPipeline from "@salesforce/apex/HerokuCmpCtrl.removeAppsAndPipeline";
import getGitHubInfo from "@salesforce/apex/HerokuCmpCtrl.getGitHubInfo";
import createRepo from "@salesforce/apex/GitHubCmpCtrl.createRepo";
import createBranch from "@salesforce/apex/GitHubCmpCtrl.createBranch";
import selectRepository from "@salesforce/apex/HerokuCmpCtrl.selectRepository";
import selectBranches from "@salesforce/apex/HerokuCmpCtrl.selectBranches";
import getGitHubBranches from "@salesforce/apex/HerokuCmpCtrl.getGitHubBranches";
import { labels } from "./labels";
import { errorMessages } from "c/errorMessages";
import { SubStep } from "c/srvSubStep";
import { stepsStruct } from "./stepsStruct";
import { branchTemplate } from "./branchTemplate";

const SOURCE_PARAM = "0.source";
const POPUP_CHECKER_INTERVAL = 500;

export default class Heroku extends BaseService {
    @api inx = 1;
    @api title = "";
    @api desc = "";
    @api name = "";
    @api disabled = false;
    @track substeps = [];
    @track substepRerender = false;
    @track isOpen = true;
    @track loading = true;
    @track popupGit;
    @track popupGitChecker;
    @track progress = 0;
    @track branches = [];
    @track repos = [];
    @track repo = "";

    stepByStep = true;
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
    get branchesCmp() {
        return this.subStepByName("repo").components.filter(cmp => cmp.props.name.indexOf("Branch") >= 0);
    }
    get branchesOptions() {
        return this.branches
            .sort()
            .map(item => {
                return `<option value="${item}">${item}</option>`;
            })
            .join("\n");
    }
    get popupNotInit() {
        return !this.popupGit || this.popupGit.closed;
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
    clearNextSteps(curId) {
        this.substeps.slice(curId).forEach(item => {
            item.value = {};
            item.active = false;
            if (item.states.default && item.states.default.components) {
                item.states.default.components.forEach(cmp => {
                    cmp.props.value = null;
                });
            }
            item.changeState("disabled");
            item.uname = null;
            item.valid = false;
        });
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
        const valids = this.substeps.filter(item => item.valid);
        const validLen = valids.length;
        const activeInx = this.substeps.map(item => item.valid).indexOf(false);
        valids.forEach(item => {
            item.active = false;
        });
        if (activeInx < len && activeInx >= 0) {
            try {
                this.substeps[activeInx].active = true;
                this.substeps.slice(activeInx + 1).forEach(item => {
                    item.valid = false;
                });
            } catch (e) {
                console.error(e);
            }
        }
        if (len > 0) {
            this.progress = Math.ceil((validLen * 100) / len);
        }
        this.doSubRerender();
    }

    popupCenter(url, w, h) {
        const dualScreenLeft = window.screenLeft || window.screenX;
        const dualScreenTop = window.screenTop || window.screenY;

        const width = window.innerWidth
            ? window.innerWidth
            : document.documentElement.clientWidth
            ? document.documentElement.clientWidth
            : screen.width;
        const height = window.innerHeight
            ? window.innerHeight
            : document.documentElement.clientHeight
            ? document.documentElement.clientHeight
            : screen.height;

        const systemZoom = width / window.screen.availWidth;
        const left = (width - w) / 2 / systemZoom + dualScreenLeft;
        const top = (height - h) / 2 / systemZoom + dualScreenTop;
        const newWindow = window.open(
            url,
            "_blank",
            "scrollbars=no,location=no,resizable=no, width=" +
                w / systemZoom +
                ", height=" +
                h / systemZoom +
                ", top=" +
                top +
                ", left=" +
                left
        );
        if (window.focus) newWindow.focus();
        return newWindow;
    }
    checkPopupClose() {
        return new Promise(resolve => {
            clearTimeout(this.popupGitChecker);
            this.popupGitChecker = setTimeout(() => {
                if (this.popupGit) {
                    resolve(this.popupGit.closed);
                } else {
                    resolve(false);
                }
            }, POPUP_CHECKER_INTERVAL);
        });
    }

    async newBranchModal() {
        return await new Promise((resolve, reject) => {
            BaseService.showModal(
                labels.createNewBranch,
                branchTemplate.replace("[options]", this.branchesOptions),
                [
                    {
                        label: labels.cancel,
                        variant: "neutral",
                        name: "cancel",
                        callback: () => {
                            resolve(null);
                        },
                    },
                    {
                        label: labels.create,
                        variant: "brand",
                        name: "create",
                        callback: ({ values }) => {
                            if (values.filter(item => !!item.value).length === values.length) {
                                resolve(values.reduce((obj, item) => ((obj[item.name] = item.value), obj), {}));
                            } else {
                                reject(errorMessages.heroku.branchNotFound);
                            }
                        },
                    },
                ],
                () => {
                    resolve(null);
                }
            );
        });
    }
    async newRepoModal() {
        return await new Promise((resolve, reject) => {
            BaseService.showModal(
                labels.createNewRepository,
                `<div class="slds-form-element">
                          <label class="slds-form-element__label" for="text-input-id-1">
                            <abbr class="slds-required" title="required">*</abbr>${labels.repositoryName}</label>
                          <div class="slds-form-element__control">
                            <input type="text" id="repoName" name="repoName" required class="slds-input" />
                          </div>
                        </div>`,
                [
                    {
                        label: labels.cancel,
                        variant: "neutral",
                        name: "cancel",
                        callback: () => {
                            resolve(null);
                        },
                    },
                    {
                        label: labels.create,
                        variant: "brand",
                        name: "create",
                        callback: ({ values }) => {
                            const repoName = values.filter(item => {
                                return item.name === "repoName";
                            });
                            if (repoName.length > 0) {
                                resolve(repoName[0].value);
                            } else {
                                reject(errorMessages.heroku.repositoryNotFound);
                            }
                        },
                    },
                ],
                () => {
                    resolve(null);
                }
            );
        });
    }
    createNewRepo() {
        this.newRepoModal().then(repoName => {
            if (repoName) {
                BaseService.showSpinner(true, labels.createRepository);
                BaseService.invokeServiceMethod(createRepo, { repoName })
                    .then(res => {
                        const repoStep = this.subStepByName("repo");
                        const cmp = this.cmpByName(repoStep, "repo");
                        if (cmp) {
                            cmp.props.options.push({ value: res.newRepoFullName, label: res.newRepoFullName });
                            cmp.props.value = res.newRepoFullName;
                            repoStep.value = res.newRepoFullName;
                            this.repo = res.newRepoFullName;
                            repoStep.changeState();
                            repoStep.valid = false;
                            this.calcProc();
                        }
                    })
                    .catch(err => {
                        BaseService.handleExceptions(err, errorMessages.heroku.createRepository);
                    })
                    .finally(() => {
                        BaseService.showSpinner(false);
                    });
            }
        });
    }
    createNewBranch(destination) {
        this.newBranchModal().then(res => {
            if (res) {
                BaseService.showSpinner(true, labels.createBranch);
                BaseService.invokeServiceMethod(createBranch, {
                    repoName: this.repo,
                    newBranchName: res.newBranchName,
                    parentBranchName: res.parentBranchName,
                })
                    .then(() => {
                        const repoStep = this.subStepByName("repo");
                        this.branchesCmp.forEach(cmp =>
                            cmp.props.options.push({ value: res.newBranchName, label: res.newBranchName })
                        );
                        this.branches.push(res.newBranchName);
                        const cmp = this.cmpByName(repoStep, destination);
                        if (cmp) {
                            cmp.props.value = res.newBranchName;
                        }
                        const valid = repoStep.components.filter(item => !item.props.value).length === 0;
                        repoStep.changeState(valid ? "unsaved" : "default");
                        this.calcProc();
                    })
                    .catch(err => {
                        BaseService.handleExceptions(err, errorMessages.heroku.createBranch);
                    })
                    .finally(() => {
                        BaseService.showSpinner(false);
                    });
            }
        });
    }
    async showPopupGit(url) {
        if (this.popupNotInit) {
            this.popupGit = this.popupCenter(url, 800, 600);
        }
        this.popupGit.focus();
        this.handlePopupClose().then(async () => {
            this.loading = true;
            await this.getGitInfo();
            this.calcProc();
            this.loading = false;
        });
    }
    async getOAuthLink() {
        let OAuthUrl = "";
        try {
            const res = await BaseService.invokeServiceMethodWithoutParameters(getOAuthUrl);
            if (res && res.url) {
                OAuthUrl = res.url;
            }
        } catch (e) {
            console.error(e);
            BaseService.showToast(errorMessages.heroku.link);
        }
        if (!OAuthUrl) {
            this.loading = false;
        }
        return OAuthUrl;
    }
    async confirmRevoke() {
        // eslint-disable-next-line no-return-await
        return await new Promise(resolve =>
            BaseService.showModal(
                null,
                `<h2 class="slds-text-heading_small">${labels.areYouSure}</h2>
                           <p>${labels.revokeHeroku}</p>`,
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
    async confirmRemovePipeline() {
        // eslint-disable-next-line no-return-await
        return await new Promise(resolve =>
            BaseService.showModal(
                null,
                `<h2 class="slds-text-heading_small">${labels.areYouSure}</h2>
                           <p>${labels.removePipeline}</p>`,
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
    async checkCode() {
        return new Promise(resolve => {
            if (BaseService.getUrlParameter(SOURCE_PARAM) === "heroku") {
                const code = BaseService.getUrlParameter("code");
                const state = BaseService.getUrlParameter("state");
                if (code !== "") {
                    BaseService.invokeServiceMethod(exchangeCodeForAccessToken, { code, state })
                        .then(() => {
                            this.getUserInfo().then(() => {
                                resolve(true);
                                this.calcProc();
                            });
                        })
                        .catch(e => {
                            console.error(e);
                            this.loading = false;
                            resolve(false);
                            BaseService.showToast(errorMessages.heroku.exchangeCode);
                        });
                } else {
                    resolve(false);
                }
                window.history.replaceState({}, document.title, document.location.pathname);
            } else {
                resolve(false);
            }
        });
    }
    async selectRepository(name) {
        BaseService.showSpinner(true, labels.applyingRepository);
        BaseService.invokeServiceMethod(selectRepository, { name })
            .then(async () => {
                await this.selectBranches();
            })
            .catch(err => {
                BaseService.handleExceptions(err, errorMessages.heroku.applyingRepository);
                BaseService.showSpinner(false);
            });
    }
    async selectBranches() {
        BaseService.showSpinner(true, labels.applyingBranches);
        const repoStep = this.subStepByName("repo");
        const params = this.branchesCmp.reduce((obj, item) => ((obj[item.props.name] = item.props.value), obj), {});
        BaseService.invokeServiceMethod(selectBranches, params)
            .then(async () => {
                BaseService.showSpinner(false);
                BaseService.showToast(null, labels.setupCompleted, "success");
                repoStep.valid = true;
                repoStep.changeState();
                this.calcProc();
            })
            .catch(err => {
                BaseService.handleExceptions(err, errorMessages.heroku.applyingBranches);
            })
            .finally(() => {
                BaseService.showSpinner(false);
            });
    }
    createAppsAndPipeline() {
        BaseService.showSpinner(true, labels.creatingPipeline);
        BaseService.invokeServiceMethodWithoutParameters(createAppsAndPipeline)
            .then(async (res) => {
                const pipeline = this.subStepByName("pipeline");
                this.clearNextSteps(pipeline.id);
                pipeline.valid = true;
                pipeline.default.rightText = res.pipelineUrl
                    ? { link: res.pipelineUrl, label: this.labels.openPipeline }
                    : null;
                pipeline.changeState("valid");
                await this.getGitInfo();
                this.calcProc();
            })
            .catch(err => {
                BaseService.handleExceptions(err, errorMessages.heroku.creatingPipeline);
            })
            .finally(() => {
                BaseService.showSpinner(false);
            });
    }
    removeAppsAndPipeline() {
        BaseService.showSpinner(true, labels.deletingPipeline);
        BaseService.invokeServiceMethodWithoutParameters(removeAppsAndPipeline)
            .then(() => {
                const pipeline = this.subStepByName("pipeline");
                pipeline.valid = false;
                pipeline.default.rightText = null;
                this.clearNextSteps(pipeline.id);
                pipeline.changeState();
                this.calcProc();
            })
            .catch(err => {
                BaseService.handleExceptions(err, errorMessages.heroku.deletingPipeline);
            })
            .finally(() => {
                BaseService.showSpinner(false);
            });
    }
    revokeToken() {
        BaseService.invokeServiceMethodWithoutParameters(revokeAccessToken)
            .then(() => {
                const connect = this.subStepByName("connect");
                connect.valid = false;
                this.subStepByName("pipeline").default.rightText = null;
                this.clearNextSteps(connect.id);
                connect.userName = "";
                this.calcProc();
            })
            .catch(e => {
                console.error(e);
                BaseService.showToast(errorMessages.heroku.revoke);
            });
    }
    getGitInfo() {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethodWithoutParameters(getGitHubInfo)
                .then(res => {
                    const gitStep = this.subStepByName("git");
                    gitStep.valid = res.isGitConnected;
                    if (res.isGitConnected) {
                        gitStep.user = res.userName;
                        gitStep.changeState("valid");
                        const repoStep = this.subStepByName("repo");
                        const repoCmp = this.cmpByName(repoStep, "repo");
                        if (repoCmp) {
                            repoCmp.props.value = res.selectedRepo;
                        }
                        repoStep.valid = !!res.selectedRepo;
                        this.repo = res.selectedRepo;
                        if (res.repos) {
                            this.repos = res.repos;
                            this.cmpByName(repoStep, "repo").props.options = this.repos.map(item => {
                                return { value: item, label: item };
                            });
                        }
                        repoStep.changeState();
                        this.branches = [];
                        if (res.qaBranch) {
                            this.cmpByName(repoStep, "qaBranch").props.value = res.qaBranch;
                        }
                        if (res.stagingBranch) {
                            this.cmpByName(repoStep, "stagingBranch").props.value = res.stagingBranch;
                        }
                        const branchesValid = !!res.qaBranch && !!res.stagingBranch;
                        repoStep.valid = branchesValid;
                        if (branchesValid) {
                            repoStep.changeState();
                        }
                    } else {
                        gitStep.changeState();
                    }

                    resolve(res);
                })
                .catch(e => {
                    console.error(e);
                    e.forEach(error => {
                        BaseService.showToast(error.message, null, error.severity);
                    });
                    reject(e);
                });
        });
    }
    getGitHubBranches(repoFullName) {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethod(getGitHubBranches, { repoFullName })
                .then(res => {
                    this.branches = res.branches;
                    const repoStep = this.subStepByName("repo");
                    repoStep.changeState();
                    this.cmpByName(repoStep, "qaBranch").props.options = this.branches.map(item => {
                        return { value: item, label: item };
                    });
                    this.cmpByName(repoStep, "stagingBranch").props.options = this.branches.map(item => {
                        return { value: item, label: item };
                    });
                    resolve(res);
                })
                .catch(e => {
                    console.error(e);
                    e.forEach(error => {
                        BaseService.showToast(error.message, null, error.severity);
                    });
                    reject(e);
                });
        });
    }
    getAppsAndPipelineInfo() {
        return new Promise((resolve, reject) => {
            BaseService.invokeServiceMethodWithoutParameters(getAppsAndPipelineInfo)
                .then(res => {
                    const pipeline = this.subStepByName("pipeline");
                    pipeline.valid = res.isPipelineAndAppsExists;
                    pipeline.default.rightText = res.pipelineUrl
                        ? { link: res.pipelineUrl, label: this.labels.openPipeline }
                        : null;
                    pipeline.changeState(pipeline.valid ? "valid" : "default");
                    resolve(res);
                })
                .catch(e => {
                    console.error(e);
                    e.forEach(error => {
                        BaseService.showToast(error.message, null, error.severity);
                    });
                    reject(e);
                });
        });
    }
    getUserInfo() {
        return new Promise(resolve => {
            BaseService.invokeServiceMethodWithoutParameters(getAuthorizationInfo)
                .then(res => {
                    const connect = this.subStepByName("connect");
                    connect.valid = res.isAuthorized;
                    if (connect.valid) {
                        connect.userName = res.userName;
                    } else {
                        connect.userName = "";
                    }
                    resolve(connect.valid);
                })
                .catch(e => {
                    console.error(e);
                    resolve(false);
                    BaseService.showToast(errorMessages.heroku.userInfo);
                });
        });
    }
    async getGitLink() {
        let gitUrl = "";
        try {
            const res = await BaseService.invokeServiceMethodWithoutParameters(getConnectGitHubUrl);
            if (res && res.url) {
                gitUrl = res.url;
            }
        } catch (e) {
            console.error(e);
            e.forEach(error => {
                BaseService.showToast(error.message, null, error.severity);
            });
        }
        if (!gitUrl) {
            this.loading = false;
        }
        return gitUrl;
    }

    async handlePopupClose() {
        return new Promise(async resolve => {
            let closed;
            do {
                closed = await this.checkPopupClose();
            } while (!closed);
            resolve(true);
        });
    }
    handleOpen() {
        if (!this.disabled) {
            this.isOpen = !this.isOpen;
        }
    }
    async handleChangeValue({ detail }) {
        switch (detail.step) {
            case "repo":
                const repoStep = this.subStepByName(detail.step);
                if (detail.name === "repo") {
                    this.repo = detail.value;
                    this.branchesCmp.forEach(cmp => {
                        cmp.props.value = null;
                    });
                    BaseService.showSpinner(true);
                    await this.getGitHubBranches(detail.value);
                    BaseService.showSpinner(false);
                    repoStep.valid = false;
                }
                this.cmpByName(repoStep, detail.name).props.value = detail.value;
                const valid = repoStep.components.filter(item => !item.props.value).length === 0;
                repoStep.changeState(valid ? "unsaved" : "default");
                this.calcProc();
                break;
            default:
                console.error("Unexpected step", detail.step, detail);
                break;
        }
    }
    handleButtonClick({ detail }) {
        switch (detail.step) {
            case "repo":
                if (detail.name === "repo") {
                    this.createNewRepo();
                } else {
                    this.createNewBranch(detail.name);
                }
                break;
            default:
                console.error("Unexpected step", detail.step, detail);
                break;
        }
    }
    async handleRightButtonClick({ detail }) {
        switch (detail.step) {
            case "connect":
                this.handleConnectClick(detail.step);

                break;
            case "pipeline":
                if (!this.subStepByName(detail.step).valid) {
                    this.createAppsAndPipeline();
                } else {
                    this.removePipeline();
                }
                break;
            case "git":
                if (!this.subStepByName(detail.step).valid) {
                    const link = await this.getGitLink();
                    if (link) {
                        this.showPopupGit(link);
                    }
                }
                break;
            case "repo":
                this.selectRepository(this.repo);
                break;
            default:
                console.error("Unexpected step", detail.step, detail);
                break;
        }
    }
    async removePipeline() {
        if (await this.confirmRemovePipeline()) {
            this.removeAppsAndPipeline();
        }
    }
    async handleConnectClick(orgName) {
        if (!this.disabled) {
            const org = this.subStepByName(orgName);
            if (org) {
                if (org.valid) {
                    if (await this.confirmRevoke()) {
                        this.revokeToken();
                    }
                } else {
                    this.loading = true;
                    document.location.href = await this.getOAuthLink();
                }
            }
        }
    }
    async connectedCallback() {
        this.subStepByName("connect").userName = "";
        const userInfo = await this.getUserInfo();
        if (userInfo || (await this.checkCode())) {
            Promise.all([this.getAppsAndPipelineInfo(), this.getGitInfo()]).then(async () => {
                if (this.repo) {
                    await this.getGitHubBranches(this.repo);
                }
                this.calcProc();
                this.loading = false;
            });
        } else {
            this.calcProc();
            this.loading = false;
        }
    }
    constructor() {
        super();
        this.substeps = stepsStruct.map((item, inx) => new SubStep(inx, item));
    }
}
