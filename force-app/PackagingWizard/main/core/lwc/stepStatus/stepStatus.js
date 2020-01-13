import { LightningElement, api } from "lwc";

export default class StepStatus extends LightningElement {
    @api complete = false;
    @api number = 1;
    @api progress = 0;
    get progressValue() {
        return this.complete ? 100 : this.progress;
    }
    get numberValue() {
        return this.complete ? "" : this.number;
    }
    get circleD() {
        const isLong = this.progressValue > 50 ? 1 : 0;
        const arcX = Math.cos(2 * Math.PI * (this.progressValue / 100));
        const arcY = Math.sin(2 * Math.PI * (this.progressValue / 100));
        return `M 1 0 A 1 1 0 ${isLong} 1 ${arcX} ${arcY} L 0 0`;
    }
    get progressRingCls() {
        return `slds-progress-ring ${
            this.complete ? "slds-progress-ring_complete " : this.progress > 0 ? "slds-progress-ring_active-step " : ""
        }slds-progress-ring_large`;
    }
}
