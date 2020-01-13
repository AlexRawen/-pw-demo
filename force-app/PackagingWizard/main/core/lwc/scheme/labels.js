import schemeQABranch from "@salesforce/label/c.schemeQABranch";
import schemeStagingBranch from "@salesforce/label/c.schemeStagingBranch";
import schemeQAApp from "@salesforce/label/c.schemeQAApp";
import schemeStagingApp from "@salesforce/label/c.schemeStagingApp";
import schemeScratchOrg from "@salesforce/label/c.schemeScratchOrg";
import schemeDevHub from "@salesforce/label/c.schemeDevHub";
import schemeQAOrg from "@salesforce/label/c.schemeQAOrg";
import schemeStagingOrg from "@salesforce/label/c.schemeStagingOrg";
import schemeGitTitle from "@salesforce/label/c.schemeGitTitle";
import schemeHerokuTitle from "@salesforce/label/c.schemeHerokuTitle";
import schemeSalesforceTitle from "@salesforce/label/c.schemeSalesforceTitle";
import schemeUnlockedPackage from "@salesforce/label/c.schemeUnlockedPackage";
import schemeManagedPackage from "@salesforce/label/c.schemeManagedPackage";

export const labels = {
    qa: {
        branch: schemeQABranch,
        app: schemeQAApp,
        org: schemeQAOrg,
    },
    staging: {
        branch: schemeStagingBranch,
        app: schemeStagingApp,
        org: schemeStagingOrg,
    },
    titles: {
        git: schemeGitTitle,
        heroku: schemeHerokuTitle,
        sf: schemeSalesforceTitle,
    },
    scratchOrg: schemeScratchOrg,
    devHub: schemeDevHub,
    unlockedPackage: schemeUnlockedPackage,
    managedPackage: schemeManagedPackage,
};
