public with sharing class GitHubCmpCtrl {

    @AuraEnabled
    public static Response createRepo(String request) {
        Response resp = new Response();
        try {
            CreateRepoRequest req = (CreateRepoRequest) JSON.deserialize(request, CreateRepoRequest.class);
            // actual new repo name, could be different from requested, e.g. '&%^(*O//IGG^I656548   ' -> '-O-IGG-I656548-'
            String newRepoFullName = GitHubSvc.createRepo(req.repoName);
            resp.setData('newRepoFullName', newRepoFullName);
            // GitHubSvc uses KolkrabbiApi to get AccessToken for GitHubApi
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public class CreateRepoRequest{
        public String repoName;
    }

    @AuraEnabled
    public static Response createBranch(String request) {
        Response resp = new Response();
        try {
            CreateBranchRequest req = (CreateBranchRequest) JSON.deserialize(request, CreateBranchRequest.class);
            GitHubSvc.createBranch(req.repoName, req.newBranchName, req.parentBranchName);
            // GitHubSvc uses KolkrabbiApi to get AccessToken for GitHubApi
            HerokuData.storeRefreshedAccessToken();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public class CreateBranchRequest{
        public String repoName;
        public String newBranchName;
        public String parentBranchName;
    }

}
