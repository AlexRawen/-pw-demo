public inherited sharing class KolkrabbiApi {

    private String accessToken;
    public static final String KOLKRABBI_API_URL = 'https://kolkrabbi.heroku.com';

    public KolkrabbiApi() {
        init(HerokuData.getAccessToken());
    }

    public KolkrabbiApi(String accessToken) {
        init(accessToken);
    }

    private void init(String accessToken) {
        if (String.isBlank(accessToken)) {
            throw CustomException.build('KolkrabbiApi: accessToken is empty.');
        }
        this.accessToken = accessToken;
    }

    private HttpRequest basicKolkrabbiRequest(String method, String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(KOLKRABBI_API_URL + endpoint);
        request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
        request.setHeader('Content-Type', 'application/json');
        setAuthHeader(request);
        return request;
    }

    private void setAuthHeader(HttpRequest request) {
        request.setHeader('Authorization', 'Bearer ' + this.accessToken);
    }

    private void refreshAccessToken() {
        this.accessToken = HerokuApi.refreshAccessToken(HerokuData.getRefreshToken());
    }

    public HttpResponse makeRequest(String method, String endpoint, String body) {
        return makeRequest(method, endpoint, body, (Set<Integer>) null);
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Integer successCode) {
        return makeRequest(method, endpoint, body, new Set<Integer>{successCode});
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Set<Integer> successCodes) {
        HttpRequest request = basicKolkrabbiRequest(method, endpoint);
        if ('PATCH'.equalsIgnoreCase(method)) {
            request.setMethod('POST');
            request.setHeader('X-HTTP-Method-Override', 'PATCH');
        }

        if (body != null) {
            request.setBody(body);
        }

        Http http = new Http();
        HttpResponse response = http.send(request);

        // Refresh token and retry request if "401 unauthorized" received
        if (response.getStatusCode() == 401) {
            this.refreshAccessToken();
            setAuthHeader(request);
            response = http.send(request);
        }

        if (successCodes == null || successCodes.contains(response.getStatusCode())) {
            return response;
        } else {
            String errMsg = 'Heroku: ' + HerokuApi.buildErrorMessage(response);
            throw (response.getStatusCode() == 401)
                ? AuthorizationException.build(errMsg)
                : CustomException.build(errMsg);
        }
    }

    public String getGitHubAccessToken() {
        HttpResponse response = makeRequest('GET', '/account/github/token', null, new Set<Integer>{200, 404});
        if (response.getStatusCode() == 200) {
            KolkrabbiApiGitHubTokenResp respWrp = 
                (KolkrabbiApiGitHubTokenResp) JSON.deserialize(response.getBody(), KolkrabbiApiGitHubTokenResp.class);
            return respWrp.github.token;
        } else {
            return null;
        }
    }

    public KolkrabbiApiGitHubInfoResp getAppInfo(String appId) {
        HttpResponse response = makeRequest('GET', '/apps/' + appId + '/github', null, new Set<Integer>{200, 404});
        if (response.getStatusCode() == 200) {
            KolkrabbiApiGitHubInfoResp respWrp = 
                (KolkrabbiApiGitHubInfoResp) JSON.deserialize(response.getBody(), KolkrabbiApiGitHubInfoResp.class);
            return respWrp;
        } else {
            return null;
        }
    }

    // if repo has been already set, selected repo would not be "overridden" with the new value.
    // you need to remove previous value first.
    public void setAppRepository(String appId, String repoFullName) {
        String reqBody = '{"repo":"' + repoFullName + '"}';
        HttpResponse response = makeRequest('POST', '/apps/' + appId + '/github', reqBody, 201);
        KolkrabbiApiGitHubInfoResp respWrp = 
            (KolkrabbiApiGitHubInfoResp) JSON.deserialize(response.getBody(), KolkrabbiApiGitHubInfoResp.class);
    }

    public void removeAppRepository(String appId) {
        // if a repo is not set - 404 would be returned. The same 404 error is returned for no-existing app id.
        makeRequest('DELETE', '/apps/' + appId + '/github', null, new Set<Integer>{200, 404});
    }

    // if branch has been already set, selected branch would not be "overridden" with the new value.
    // you need to de-select previous value first.
    public void setAppBranch(String appId, String branchName) {
        String reqBody = '{"auto_deploy":true,"branch":"' + branchName + '"}';
        makeRequest('PATCH', '/apps/' + appId + '/github', reqBody, 200);
    }

    public void removeAppBranch(String appId) {
        String reqBody = '{"auto_deploy": false}';
        makeRequest('PATCH', '/apps/' + appId + '/github', reqBody, 200);
    }
}
