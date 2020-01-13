import errHerokuLink from "@salesforce/label/c.errHerokuLink";
import errHerokuExchangeCode from "@salesforce/label/c.errHerokuExchangeCode";
import errHerokuUserInfo from "@salesforce/label/c.errHerokuUserInfo";
import errHerokuRevoke from "@salesforce/label/c.errHerokuRevoke";
import errOrgsAuthorization from "@salesforce/label/c.errOrgsAuthorization";
import errOrgsConnection from "@salesforce/label/c.errOrgsConnection";
import errOrgsSavePackage from "@salesforce/label/c.errOrgsSavePackage";
import errOrgsOrgInfo from "@salesforce/label/c.errOrgsOrgInfo";
import errOrgsPackageSettings from "@salesforce/label/c.errOrgsPackageSettings";
import errOrgsAuthInfo from "@salesforce/label/c.errOrgsAuthInfo";
import errHerokuBranchNotFound from "@salesforce/label/c.errHerokuBranchNotFound";
import errHerokuRepositoryNotFound from "@salesforce/label/c.errHerokuRepositoryNotFound";
import errHerokuCreateRepository from "@salesforce/label/c.errHerokuCreateRepository";
import errHerokuCreateBranch from "@salesforce/label/c.errHerokuCreateBranch";
import errHerokuApplyingRepository from "@salesforce/label/c.errHerokuApplyingRepository";
import errHerokuApplyingBranches from "@salesforce/label/c.errHerokuApplyingBranches";
import errHerokuCreatingPipeline from "@salesforce/label/c.errHerokuCreatingPipeline";
import errHerokuDeletingPipeline from "@salesforce/label/c.errHerokuDeletingPipeline";
export const errorMessages = {
    heroku: {
        link: errHerokuLink,
        exchangeCode: errHerokuExchangeCode,
        userInfo: errHerokuUserInfo,
        revoke: errHerokuRevoke,
        branchNotFound: errHerokuBranchNotFound,
        repositoryNotFound: errHerokuRepositoryNotFound,
        createRepository: errHerokuCreateRepository,
        createBranch: errHerokuCreateBranch,
        applyingRepository: errHerokuApplyingRepository,
        applyingBranches: errHerokuApplyingBranches,
        creatingPipeline: errHerokuCreatingPipeline,
        deletingPipeline: errHerokuDeletingPipeline,
    },
    orgs: {
        authorization: errOrgsAuthorization,
        connection: errOrgsConnection,
        savePackage: errOrgsSavePackage,
        orgInfo: errOrgsOrgInfo,
        packageSettings: errOrgsPackageSettings,
        authInfo: errOrgsAuthInfo,
    },
};
