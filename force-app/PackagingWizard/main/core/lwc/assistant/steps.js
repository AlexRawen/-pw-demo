import orgLabel from "@salesforce/label/c.orgLabel";
import orgDescription from "@salesforce/label/c.orgDescription";
import herokuLabel from "@salesforce/label/c.herokuLabel";
import herokuDescription from "@salesforce/label/c.herokuDescription";
export const steps = [
    {
        name: "org",
        label: orgLabel,
        description: orgDescription,
        openable: true,
    },
    {
        name: "heroku",
        label: herokuLabel,
        description: herokuDescription,
        openable: true,
    },
];
