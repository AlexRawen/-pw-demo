public with sharing class HerokuCmpCtrl {
    @AuraEnabled
    public static Response getOAuthUrl() {
        Response resp = new Response();
        try {
            resp.setData('url', HerokuSvc.getOAuthUrl());
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response getAuthorizationInfo() {
        Response resp = new Response();
        try {
            Boolean isAuthorized = HerokuSvc.isAuthorized();
            if (isAuthorized) {
                try{
                    System.debug('JORA - 1');
                    resp.setData('userName', HerokuSvc.getUserName());
                    System.debug('JORA - 2');
                } catch (AuthorizationException ex) {
                    System.debug('JORA - AuthorizationException');
                    isAuthorized = false;
                } catch (CustomException ex) {
                    System.debug('JORA - CustomException');
                    isAuthorized = false;
                }
            }
            System.debug('JORA - 4');
            resp.setData('isAuthorized', HerokuSvc.isAuthorized());
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response exchangeCodeForAccessToken(String request) {
        Response resp = new Response();
        try {
            CodeExchangeRequest req = (CodeExchangeRequest) JSON.deserialize(request, CodeExchangeRequest.class);
            HerokuSvc.exchangeCodeForAccessToken(req.code, req.state);
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    private class CodeExchangeRequest implements Validatable {
        public String code;
        // An unguessable random string. It is used to protect against cross-site request forgery attacks.
        public String state;

        // TODO - implement storage and validation of state
        public void validate() {}
    }

    @AuraEnabled
    public static Response revokeAccessToken() {
        Response resp = new Response();
        try {
            // it is not possible to revoke authorization with access token aquired throw web-flow OAuth
            // "Access not allowed to OAuth-initiated requests. Please use a self-issued OAuth authorization for access"
            // Therefore, only custom settings are cleared without actual access revoke.
            removeAppsAndPipeline();
            HerokuData.deleteAuthorization();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response createAppsAndPipeline() {
        Response resp = new Response();
        try {
            HerokuSvc.createAppsAndPipeline();
            resp.setData('pipelineUrl', HerokuSvc.getPipelineUrl());
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response removeAppsAndPipeline() {
        Response resp = new Response();
        try {
            HerokuSvc.removeAppsAndPipeline();
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response getGitHubInfo() {
        Response resp = new Response();
        try {
            String gitHubToken = HerokuSvc.getGitHubAccessToken();
            if (String.isBlank(gitHubToken)) {
                resp.setData('isGitConnected', false);
                return resp;
            } else {
                resp.setData('isGitConnected', true);
            }

            String selectedRepo = null;

            HerokuSvc.AppGitHubInfo qaApp = HerokuSvc.getAppInfo(HerokuSvc.AppStage.QA);
            if (qaApp != null) {
                // both qa and staging apps should use the same repository
                selectedRepo = qaApp.repo;
                resp.setData('selectedRepo', selectedRepo);
                resp.setData('qaBranch', qaApp.branch);
            }
            HerokuSvc.AppGitHubInfo stagingApp = HerokuSvc.getAppInfo(HerokuSvc.AppStage.STAGING);
            if (stagingApp != null) {
                resp.setData('stagingBranch', stagingApp.branch);
            }

            GitHubApi gitApi = new GitHubApi(gitHubToken);
            Map<String, Object> reposData = gitApi.listAllRepositories();
            resp.setData('userName', gitApi.requestUserName());
            resp.setData('repos', reposData.get('repos'));
            resp.setData('hasMoreRepos', reposData.get('hasMoreRepos'));

            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response getGitHubBranches(String request) {
        Response resp = new Response();
        try {
            GitHubBranchesRequest branchesReq = (GitHubBranchesRequest) JSON.deserialize(request, GitHubBranchesRequest.class);
            GitHubApi gitApi = new GitHubApi(HerokuSvc.getGitHubAccessToken());
            Map<String, Object> branchesData = gitApi.listAllBranches(branchesReq.repoFullName);

            resp.setData('branches', branchesData.get('branches'));
            resp.setData('hasMoreBranches', branchesData.get('hasMoreBranches'));

            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public class GitHubBranchesRequest {
        public String repoFullName;
    }

    @AuraEnabled
    public static Response selectRepository(String request) {
        Response resp = new Response();
        try {
            SelectNameWrp req = (SelectNameWrp) JSON.deserialize(request, SelectNameWrp.class);
            HerokuSvc.selectRepository(req.name);
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public class SelectNameWrp {
        public String name;
    }

    public class BranchesNamesWrp {
        public String qaBranch;
        public String stagingBranch;
    }

    @AuraEnabled
    public static Response selectQaBranch(String request) {
        SelectNameWrp req = (SelectNameWrp) JSON.deserialize(request, SelectNameWrp.class);
        return selectBranch(HerokuSvc.AppStage.QA, req.name);
    }

    @AuraEnabled
    public static Response selectStagingBranch(String request) {
        SelectNameWrp req = (SelectNameWrp) JSON.deserialize(request, SelectNameWrp.class);
        return selectBranch(HerokuSvc.AppStage.STAGING, req.name);
    }

    @AuraEnabled
    public static Response selectBranches(String request) {
        Response resp = new Response();
        try {
            BranchesNamesWrp req = (BranchesNamesWrp) JSON.deserialize(request, BranchesNamesWrp.class);
            HerokuSvc.selectAppBranch(HerokuSvc.AppStage.QA, req.qaBranch);
            HerokuSvc.selectAppBranch(HerokuSvc.AppStage.STAGING, req.stagingBranch);
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    private static Response selectBranch(HerokuSvc.AppStage stage, String branchName) {
        Response resp = new Response();
        try {
            HerokuSvc.selectAppBranch(stage, branchName);
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response getConnectGitHubUrl() {
        Response resp = new Response();
        try {
            resp.setData('url', HerokuSvc.getConnectGitHubUrl());
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    // get existing Heroku apps and pipeline from SFDC
    @AuraEnabled
    public static Response getAppsAndPipelineInfo() {
        Response resp = new Response();
        try {
            resp.setData('isPipelineAndAppsExists', HerokuSvc.isPipelineAndAppsExistsInSFDC());
            resp.setData('pipelineUrl', HerokuSvc.getPipelineUrl());
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }
}
