public inherited sharing class GitHubSvc {

    public static String createRepo(String newRepoName) {
        GitHubApi gitApi = new GitHubApi(HerokuSvc.getGitHubAccessToken());
        GitHubRepoWrp newRepo = gitApi.createRepo(newRepoName);
        return newRepo.full_name;
    }

    public static void createBranch(String repoName, String newBranchName, String parentBranchName) {
        GitHubApi gitApi = new GitHubApi(HerokuSvc.getGitHubAccessToken());
        String parentBranchSha = gitApi.getBranchSha(repoName, parentBranchName);
        if (parentBranchSha == null) {
            throw CustomException.build('GitHubApi: parent branch is not exists.');
        }
        gitApi.createBranch(repoName, newBranchName, parentBranchSha);
    }
}
