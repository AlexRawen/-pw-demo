public with sharing class GitHubApi {

    public static final String GITHUB_API_URL = 'https://api.github.com';
    private static final Integer PER_PAGE_LIMIT = 100;

    private String accessToken;

    public GitHubApi(String accessToken) {
        if (String.isBlank(accessToken)) {
            throw new CustomException('GitHubApi: accessToken is empty.');
        }
        this.accessToken = accessToken;
    }

    private HttpRequest basicGitHubRequest(String method, String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(GITHUB_API_URL + endpoint);
        request.setHeader('Accept', '*/*');
        request.setHeader('Authorization', 'token ' + this.accessToken);
        request.setHeader('Content-Type', 'application/json');
        return request;
    }

    public HttpResponse makeRequest(String method, String endpoint, String body) {
        return makeRequest(method, endpoint, body, (Set<Integer>) null);
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Integer successCode) {
        return makeRequest(method, endpoint, body, new Set<Integer>{successCode});
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Set<Integer> successCodes) {
        HttpRequest request = basicGitHubRequest(method, endpoint);
        if ('PATCH'.equalsIgnoreCase(method)) {
            request.setMethod('POST');
            request.setHeader('X-HTTP-Method-Override', 'PATCH');
        }

        if (body != null) {
            request.setBody(body);
        }

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (successCodes == null || successCodes.contains(response.getStatusCode())) {
            return response;
        } else {
            throw CustomException.build('GitHub: ' + buildErrorMessage(response));
        }
    }

    public String requestUserName() {
        HttpResponse gitResponse = makeRequest('GET', '/user', null, 200);
        Map<String, Object> wrp = (Map<String, Object>) JSON.deserializeUntyped(gitResponse.getBody());
        return (String) wrp.get('login');
    }

    public Map<String, Object> listAllRepositories() {
        List<String> allRepos = new List<String>();
        Boolean hasMoreRepos = true;
        Integer pageCount = 1;

        while (hasMoreRepos && Limits.getCallouts() < 90) {
            HttpResponse gitResponse = makeRequest(
                'GET', 
                '/user/repos?page=' + pageCount + '&per_page=' + PER_PAGE_LIMIT, 
                null, 200);

            allRepos.addAll(getRepoNames(gitResponse));
            hasMoreRepos = hasMore(gitResponse);
            ++pageCount;
        }

        return new Map<String, Object>{
            'repos' => allRepos,
            'hasMoreRepos' => hasMoreRepos
        };
    }

    private static List<String> getRepoNames(HttpResponse resp) {
        List<String> repoNames = new List<String>();

        for (GitHubRepoWrp repo : (List<GitHubRepoWrp>) JSON.deserialize(resp.getBody(), List<GitHubRepoWrp>.class)) {
            repoNames.add(repo.full_name);
        }

        return repoNames;
    }

    private static Boolean hasMore(HttpResponse gitResponse) {
        String linkHeader = gitResponse.getHeader('Link');
        return String.isNotBlank(linkHeader) && linkHeader.containsIgnoreCase('rel="next"');
    }

    public Map<String, Object> listAllBranches(String repoFullName) {
        List<String> allBranches = new List<String>();
        Boolean hasMoreBranches = true;
        Integer pageCount = 1;

        while (hasMoreBranches && Limits.getCallouts() < 90) {
            HttpResponse gitResponse = makeRequest(
                'GET', 
                '/repos/' + repoFullName + '/branches?page=' + pageCount + '&per_page=' + PER_PAGE_LIMIT, 
                null, 200);

            allBranches.addAll(getBranchNames(gitResponse));
            hasMoreBranches = hasMore(gitResponse);
            ++pageCount;
        }

        return new Map<String, Object>{
            'branches' => allBranches,
            'hasMoreBranches' => hasMoreBranches
        };
    }

    private static List<String> getBranchNames(HttpResponse gitResponse) {
        List<String> branchNames = new List<String>();

        List<GitHubBranchWrp> branches = (List<GitHubBranchWrp>) 
            JSON.deserialize(gitResponse.getBody(), List<GitHubBranchWrp>.class);

        for (GitHubBranchWrp branch : branches) {
            branchNames.add(branch.name);
        }

        return branchNames;
    }

    public GitHubRepoWrp createRepo(String newRepoName) {
        String requestBody = JSON.serialize(new CreateRepoReqWrp(newRepoName));
        HttpResponse gitResponse = makeRequest('POST', '/user/repos', requestBody, 201);
        return (GitHubRepoWrp) JSON.deserialize(gitResponse.getBody(), GitHubRepoWrp.class);
    }

    public class CreateRepoReqWrp{
        public String name;
        public Boolean auto_init;

        public CreateRepoReqWrp(String name) {
            this.name = name;
            this.auto_init = true;
        }
    }

    public String getBranchSha(String fullRepoName, String branchName) {
        HttpResponse gitResponse = makeRequest('GET',
                '/repos/' + fullRepoName + '/git/ref/heads/' + EncodingUtil.urlEncode(branchName, 'UTF-8'), null, 200);
        return getSha(gitResponse.getBody());
    }

    private String getSha(String responseBody) {
        Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Object branchCommit = respMap.get('object');
        if (branchCommit != null) {
            return String.valueOf(((Map<String, Object>) branchCommit).get('sha'));
        } else {
            return null;
        }
    }

    public void createBranch(String fullRepoName, String newBranchName, String commitSha) {
        String requestBody = JSON.serialize(new CreateBranchReqWrp(newBranchName, commitSha));
        makeRequest('POST', '/repos/' + fullRepoName + '/git/refs', requestBody, 201);
    }

    public class CreateBranchReqWrp{
        public String ref;
        public String sha;

        public CreateBranchReqWrp(String newBranchName, String commitSha) {
            this.ref = 'refs/heads/' + newBranchName;
            this.sha = commitSha;
        }
    }

    public static String buildErrorMessage(HttpResponse response) {
        try {
            GitHubApiErorrRespWrp errWrp = (GitHubApiErorrRespWrp) JSON.deserialize(
                response.getBody(),
                GitHubApiErorrRespWrp.class
            );
            String errMessage = errWrp.message;
            if (errWrp.errors != null) {
                for (GitHubApiErorrRespWrp.Error err : errWrp.errors) {
                    if (String.isNotBlank(err.message)) {
                        errMessage += '\n' + err.message;
                    }
                }
            }
            return errMessage;
        } catch (Exception ex) {
            return response.getStatus();
        }
    }
}
