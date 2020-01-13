import SrvCmpProps from "c/srvCmpProps";
import devhubLabel from "@salesforce/label/c.devhubLabel";
import devhubDescription from "@salesforce/label/c.devhubDescription";
import qaLabel from "@salesforce/label/c.qaLabel";
import qaDescription from "@salesforce/label/c.qaDescription";
import stagingLabel from "@salesforce/label/c.stagingLabel";
import stagingDescription from "@salesforce/label/c.stagingDescription";
import packageLabel from "@salesforce/label/c.packageLabel";
import namespaceLabel from "@salesforce/label/c.namespaceLabel";
import namespacePlaceholder from "@salesforce/label/c.namespacePlaceholder";
import nameLabel from "@salesforce/label/c.nameLabel";
import namePlaceholder from "@salesforce/label/c.namePlaceholder";
import createNamespaceLabel from "@salesforce/label/c.createNamespaceLabel";
import createNamespaceTitle from "@salesforce/label/c.createNamespaceTitle";

export const stepsStruct = [
    {
        name: "devhub",
        title: devhubLabel,
        description: devhubDescription,
        states: {
            default: {},
        },
    },
    {
        name: "qa",
        title: qaLabel,
        description: qaDescription,
        states: {
            default: {},
        },
    },
    {
        name: "staging",
        title: stagingLabel,
        description: stagingDescription,
        states: {
            default: {},
        },
    },
    {
        name: "package",
        title: packageLabel,
        description: "",
        states: {
            default: {
                components: [
                    {
                        type: "combobox",
                        props: new SrvCmpProps({
                            name: "prefix",
                            label: namespaceLabel,
                            placeholder: namespacePlaceholder,
                            required: true,
                            options: [],
                        }),
                        loader: {
                            width: "203px",
                            height: "32px",
                            className: "slds-m-right_medium",
                        },
                    },
                    {
                        type: "input",
                        props: new SrvCmpProps({
                            name: "name",
                            label: nameLabel,
                            placeholder: namePlaceholder,
                            required: true,
                            className: "slds-m-left_x-small",
                        }),
                        loader: {
                            width: "187px",
                            height: "32px",
                            className: "",
                        },
                    },
                ],
                rightButton: {
                    type: "button",
                    props: new SrvCmpProps({ label: "Save", variant: "brand", disabled: true }),
                    loader: {
                        width: "67px",
                        height: "30px",
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
            empty: {
                components: [
                    {
                        type: "button",
                        props: new SrvCmpProps({
                            name: "createNamespace",
                            variant: "base",
                            label: createNamespaceLabel,
                            title: createNamespaceTitle,
                            className: "slds-m-right_medium",
                        }),
                        loader: {
                            width: "203px",
                            height: "32px",
                            className: "slds-m-right_medium",
                        },
                    },
                    {
                        type: "input",
                        props: new SrvCmpProps({
                            name: "name",
                            label: nameLabel,
                            placeholder: namePlaceholder,
                            required: true,
                            className: "slds-m-left_x-small",
                        }),
                        loader: {
                            width: "187px",
                            height: "32px",
                            className: "",
                        },
                    },
                ],
            },
        },
    },
];
