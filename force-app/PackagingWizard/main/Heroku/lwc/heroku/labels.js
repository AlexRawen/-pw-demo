import toggleDetails from "@salesforce/label/c.toggleDetails";
import cancel from "@salesforce/label/c.cancel";
import yes from "@salesforce/label/c.yes";
import create from "@salesforce/label/c.create";
import apply from "@salesforce/label/c.apply";
import createNewBranch from "@salesforce/label/c.createNewBranch";
import createNewRepository from "@salesforce/label/c.createNewRepository";
import repositoryName from "@salesforce/label/c.repositoryName";
import createRepository from "@salesforce/label/c.createRepository";
import createBranch from "@salesforce/label/c.createBranch";
import areYouSure from "@salesforce/label/c.areYouSure";
import revokeHeroku from "@salesforce/label/c.revokeHeroku";
import removePipeline from "@salesforce/label/c.removePipeline";
import setupCompleted from "@salesforce/label/c.setupCompleted";
import applyingRepository from "@salesforce/label/c.applyingRepository";
import applyingBranches from "@salesforce/label/c.applyingBranches";
import creatingPipeline from "@salesforce/label/c.creatingPipeline";
import deletingPipeline from "@salesforce/label/c.deletingPipeline";
import connectLabel from "@salesforce/label/c.connectLabel";
import connectDescription from "@salesforce/label/c.connectDescription";
import pipelineLabel from "@salesforce/label/c.pipelineLabel";
import pipelineDescription from "@salesforce/label/c.pipelineDescription";
import gitLabel from "@salesforce/label/c.gitLabel";
import gitDescription from "@salesforce/label/c.gitDescription";
import deleteLabel from "@salesforce/label/c.delete";
import connect from "@salesforce/label/c.connect";
import repoLabel from "@salesforce/label/c.repoLabel";
import branchesLabel from "@salesforce/label/c.branchesLabel";
import selectRepositoryLabel from "@salesforce/label/c.selectRepositoryLabel";
import selectRepositoryPlaceholder from "@salesforce/label/c.selectRepositoryPlaceholder";
import qaBranchLabel from "@salesforce/label/c.qaBranchLabel";
import qaBranchPlaceholder from "@salesforce/label/c.qaBranchPlaceholder";
import stagingBranchLabel from "@salesforce/label/c.stagingBranchLabel";
import stagingBranchPlaceholder from "@salesforce/label/c.stagingBranchPlaceholder";
import openPipeline from "@salesforce/label/c.openPipeline";

export const labels = {
    toggleDetails,
    cancel,
    yes,
    delete: deleteLabel,
    create,
    apply,
    connectLabel: connect,
    createNewBranch,
    createNewRepository,
    repositoryName,
    createRepository,
    createBranch,
    areYouSure,
    revokeHeroku,
    removePipeline,
    setupCompleted,
    applyingRepository,
    applyingBranches,
    creatingPipeline,
    deletingPipeline,
    connect: {
        title: connectLabel,
        description: connectDescription,
    },
    pipeline: {
        title: pipelineLabel,
        description: pipelineDescription,
    },
    git: {
        title: gitLabel,
        description: gitDescription,
    },
    repo: {
        title: repoLabel,
    },
    branches: {
        title: branchesLabel,
    },
    selectRepositoryLabel,
    selectRepositoryPlaceholder,
    qaBranchLabel,
    qaBranchPlaceholder,
    stagingBranchLabel,
    stagingBranchPlaceholder,
    openPipeline,
};
