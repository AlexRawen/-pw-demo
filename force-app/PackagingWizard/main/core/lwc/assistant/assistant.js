import { track } from "lwc";
import BaseService from "c/baseService";
import getOrgInfo from "@salesforce/apex/SfOrgsCrtl.getOrgInfo";
import { steps } from "./steps";
import StepsWrapper from "./stepsWrapper";
import Step from "./step";
import ASSETS from "@salesforce/resourceUrl/pwAssets";
import { labels } from "./labels";
const SITE_URL = "https://www.aquivalabs.com/";
const ENABLE_DEVHUB =
    "https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_enable_devhub.htm";
export default class Assistant extends BaseService {
    labels = labels;
    @track rerender = false;
    @track showSteps = false;
    @track isDevHub = true;
    @track progress = { number: 0, percent: `0%`, style: `width: 0;` };
    @track steps = new StepsWrapper();
    @track subsProgress = {
        connect: false,
        pipeline: false,
        git: false,
        repo: false,
        branches: false,
        devhub: false,
        qa: false,
        staging: false,
        package: false,
    };
    assets = ASSETS;
    enableDevHub = ENABLE_DEVHUB;
    get copyright() {
        return {
            href: SITE_URL,
            text: labels.copyright.replace("{0}", new Date().getFullYear()),
        };
    }
    get headerLogo() {
        return this.assets + "/header.png";
    }
    get errorCurrentIsNotDevHub() {
        return labels.errorCurrentIsNotDevHub.split("{0}");
    }
    get errorCurrentIsNotDevHubBeforeLink() {
        return this.errorCurrentIsNotDevHub[0];
    }
    get errorCurrentIsNotDevHubAfterLink() {
        const message = this.errorCurrentIsNotDevHub;
        return message.length > 1 ? this.errorCurrentIsNotDevHub[1] : "";
    }

    handleStepProgress({ detail }) {
        this.steps.getByName(detail.name).progress = detail.progress;
        this.steps.getByName(detail.name).valid = detail.valid;
        this.steps.updateAvailability();
        this.rerender = !this.rerender;
        this.progress = this.steps.sumProgress;
        if (detail.subs) {
            Object.assign(this.subsProgress, detail.subs);
        }
    }
    connectedCallback() {
        BaseService.showSpinner(true);
        BaseService.invokeServiceMethodWithoutParameters(getOrgInfo)
            .then(res => {
                this.showSteps = res.isDevHub;
                this.isDevHub = res.isDevHub;
            })
            .catch(err => {
                BaseService.handleExceptions(err);
            })
            .finally(() => {
                BaseService.showSpinner(false);
            });
    }

    constructor() {
        super();
        this.steps = new StepsWrapper(
            steps.map((step, inx) => {
                return new Step(step.name, step.label, step.description, inx + 1, step.openable, step.disabled);
            })
        );
    }
}
