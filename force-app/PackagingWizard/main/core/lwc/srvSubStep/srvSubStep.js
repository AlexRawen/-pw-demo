import SrvCmpProps from "c/srvCmpProps";

export class SubStep {
    get connectLabel() {
        return this.valid ? "Disconnect" : "Connect";
    }
    get connectVariant() {
        return this.valid ? (this.name === "connect" ? "destructive" : "neutral") : "brand";
    }
    set userName(val) {
        this.user = val;
        this.rightButton = {
            type: "button",
            props: new SrvCmpProps({ label: this.connectLabel, variant: this.connectVariant }),
            loader: {
                width: "102px",
                height: "32px",
                className: "",
            },
        };
    }
    get styleCls() {
        return `slds-progress__item${this.valid ? " slds-is-completed" : ""}`;
    }
    get default() {
        return this.states.default;
    }
    get state() {
        return this.states[this.currentState] || this.default;
    }
    set rightButton(val) {
        this.state.rightButton = val;
    }
    get rightButton() {
        if (
            !!this.state.rightButton &&
            !!this.default.rightButton &&
            (this.default.rightButton.type === this.state.rightButton.type || !this.state.rightButton.type)
        ) {
            return {
                props: new SrvCmpProps(Object.assign({}, this.default.rightButton.props, this.state.rightButton.props)),
                loader: Object.assign({}, this.default.rightButton.loader || {}, this.state.rightButton.loader || {}),
            };
        } else {
            return this.state.rightButton;
        }
    }
    get rightText() {
        const rightText = this.state.rightText || this.default.rightText;
        return (
            rightText ||
            (rightText !== null
                ? this.valid && this.user && this.user.length > 0
                    ? `Connected as ${this.user}`
                    : ""
                : null)
        );
    }
    set rightText(val) {
        this.state.rightText = val;
    }
    get components() {
        if (this.state.rewrite === true) {
            return this.state.components;
        } else {
            const stComponents = this.state.components || [];
            const defComponents = this.default.components || [];

            let components = stComponents.slice(0);
            const newCmpNames = stComponents.map(cmp => cmp.props.name);
            const defCmpNames = defComponents.map(cmp => cmp.props.name);
            components.forEach(cmp => {
                const defInx = defCmpNames.indexOf(cmp.props.name);
                if ((defInx >= 0 && cmp.type === defComponents[defInx].type) || !cmp.props.type) {
                    cmp.type = defComponents[defInx].type;
                    cmp.props = new SrvCmpProps(Object.assign({}, defComponents[defInx].props, cmp.props));
                    cmp.loader = Object.assign({}, defComponents[defInx].loader, cmp.loader);
                }
            });
            components = components.concat(defComponents.filter(cmp => newCmpNames.indexOf(cmp.props.name) < 0));
            return components;
        }
    }
    set components(val) {
        this.state.components = val;
    }
    createDisabledState() {
        if (!this.states.hasOwnProperty("disabled")) {
            let disState = {};
            if (this.default.rightButton) {
                disState.rightButton = {
                    type: this.default.rightButton.type,
                    props: {
                        disabled: true,
                    },
                };
            }
            if (this.default.components) {
                disState.components = [];
                this.default.components.forEach(cmp => {
                    disState.components.push({ props: { name: cmp.props.name, disabled: true } });
                });
            }
            this.states.disabled = disState;
        }
    }
    changeState(stateName = "default") {
        this.currentState = this.states.hasOwnProperty(stateName) ? stateName : "default";
    }

    constructor(id, { name, title, description, valid, states }) {
        this.id = id || 1;
        this.name = name || "default";
        this.title = title || "";
        this.description = description || "";
        this.valid = valid || false;
        this.currentState = "default";
        this.states = states;
        this.uname = null;
        this.value = {};
        this.active = false;
        this.createDisabledState();
    }
}
