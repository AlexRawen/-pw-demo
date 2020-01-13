import { LightningElement, api } from "lwc";
import { labels } from "./labels";

export default class Scheme extends LightningElement {
    @api connect = false;
    @api pipeline = false;
    @api git = false;
    @api repo = false;
    @api branches = false;
    @api devhub = false;
    @api qa = false;
    @api staging = false;
    @api package = false;

    labels = labels;

    getStyleClass(valid, hasData, scratch) {
        return `pw-scheme-block ${scratch ? "pw-scheme-block__scratch" : ""} ${
            hasData && !valid ? "pw-scheme-block__has-data" : ""
        } ${valid ? "pw-scheme-block__valid" : ""}`;
    }
    get branchValid() {
        return this.pipelineValid && this.branches;
    }
    get pipelineValid() {
        return this.pipeline && this.git && this.package;
    }
    get devhubValid() {
        return this.devhub;
    }
    get scratchValid() {
        return this.devhubValid && this.pipelineValid;
    }
    get qaValid() {
        return this.scratchValid && this.qa;
    }
    get stagingValid() {
        return this.scratchValid && this.staging;
    }
    get devhubCls() {
        return this.getStyleClass(this.devhubValid, false, false);
    }
    get branchCls() {
        return this.getStyleClass(this.branchValid, this.branches, false);
    }
    get scratchCls() {
        return this.getStyleClass(this.scratchValid, false, true);
    }
    get piplineCls() {
        return this.getStyleClass(this.pipelineValid, this.pipeline && this.git, false);
    }
    get qaCls() {
        return this.getStyleClass(this.qaValid, this.qa, false);
    }
    get stagingCls() {
        return this.getStyleClass(this.stagingValid, this.staging, false);
    }
}
