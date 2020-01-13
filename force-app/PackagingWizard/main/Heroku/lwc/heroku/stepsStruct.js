import SrvCmpProps from "c/srvCmpProps";
import { labels } from "./labels";
export const stepsStruct = [
    {
        name: "connect",
        title: labels.connect.title,
        description: labels.connect.description,
        states: {
            default: {},
        },
    },
    {
        name: "pipeline",
        title: labels.pipeline.title,
        description: labels.pipeline.description,
        states: {
            default: {
                rightButton: {
                    type: "button",
                    props: new SrvCmpProps({ label: labels.create, variant: "brand" }),
                    loader: {
                        width: "74px",
                        height: "32px",
                        className: "slds-m-left_x-small",
                    },
                },
            },
            valid: {
                rightButton: { props: { label: labels.delete, variant: "neutral" } },
            },
        },
    },
    {
        name: "git",
        title: labels.git.title,
        description: labels.git.description,
        states: {
            default: {
                rightButton: {
                    type: "button",
                    props: new SrvCmpProps({ label: labels.connectLabel, variant: "brand" }),
                    loader: {
                        width: "102px",
                        height: "32px",
                        className: "slds-m-left_x-small",
                    },
                },
            },
            valid: {},
        },
        rewrite: true,
    },
    {
        name: "repo",
        title: labels.repo.title,
        description: "",
        states: {
            default: {
                components: [
                    {
                        type: "advcombobox",
                        props: new SrvCmpProps({
                            name: "repo",
                            label: labels.selectRepositoryLabel,
                            placeholder: labels.selectRepositoryPlaceholder,
                            options: [],
                        }),
                        loader: {
                            width: "526px",
                            height: "32px",
                            className: "",
                        },
                    },
                    {
                        type: "advcombobox",
                        props: new SrvCmpProps({
                            name: "qaBranch",
                            label: labels.qaBranchLabel,
                            placeholder: labels.qaBranchPlaceholder,
                            options: [],
                        }),
                        loader: {
                            width: "258px",
                            height: "32px",
                            className: "slds-m-top_small",
                        },
                    },
                    {
                        type: "advcombobox",
                        props: new SrvCmpProps({
                            name: "stagingBranch",
                            label: labels.stagingBranchLabel,
                            placeholder: labels.stagingBranchPlaceholder,
                            options: [],
                            className: "slds-m-left_x-small",
                        }),
                        loader: {
                            width: "258px",
                            height: "32px",
                            className: "slds-m-top_small slds-m-left_x-small",
                        },
                    },
                ],
                rightButton: {
                    type: "button",
                    props: new SrvCmpProps({ label: labels.apply, variant: "brand", disabled: true }),
                    loader: {
                        width: "102px",
                        height: "32px",
                        className: "slds-m-left_x-small",
                    },
                },
            },
            unsaved: {
                rightButton: {
                    type: "button",
                    props: { disabled: false },
                },
            },
        },
    },
];
