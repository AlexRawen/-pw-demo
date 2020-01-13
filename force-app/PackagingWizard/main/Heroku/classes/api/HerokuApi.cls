public with sharing class HerokuApi {
    public static final String HEROKU_API_URL = 'https://api.heroku.com';
    public static final String HEROKU_DASHBOARD_URL = 'https://dashboard.heroku.com';
    public static final String HEROKU_ID_URL = 'https://id.heroku.com';

    public static final String PIPELINE_STAGE_DEVELOPMENT = 'development';
    public static final String PIPELINE_STAGE_STAGING = 'staging';

    private static final String OAUTH_APP_HEROKU = 'Heroku';
    private static final String OAUTH_APP_HEROKU_SANDBOX = 'HerokuSandbox';

    private static OAuthApp__mdt oauthApp{
        get{
            if (oauthApp == null) {
                oauthApp = OAuthAppData.getOAuthAppByDevName(
                        Env.isSandbox() ? OAUTH_APP_HEROKU_SANDBOX : OAUTH_APP_HEROKU
                    );
            }
            return oauthApp;
        }
        set;
    }

    private String accessToken;
    private String refreshToken;

    public HerokuApi() {
        init(HerokuData.getAccessToken(), HerokuData.getRefreshToken());
    }

    public HerokuApi(String accessToken, String refreshToken) {
        init(accessToken, refreshToken);
    }

    private void init(String accessToken, String refreshToken) {
        if (String.isBlank(accessToken)) {
            throw new CustomException('HerokuApi: accessToken is empty.');
        }
        if (String.isBlank(accessToken)) {
            throw new CustomException('HerokuApi: refreshToken is empty.');
        }
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }

    private HttpRequest basicHerokuRequest(String method, String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(HEROKU_API_URL + endpoint);
        request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
        request.setHeader('Content-Type', 'application/json');
        setAuthHeader(request);
        return request;
    }

    private void setAuthHeader(HttpRequest request) {
        request.setHeader('Authorization', 'Bearer ' + this.accessToken);
    }

    public static String getOAuthEndpointUrl() {
        return HEROKU_ID_URL + '/oauth/authorize?client_id=' + oauthApp.ClientId__c + 
            '&response_type=code&scope=global';
    }

    public static Response exchangeCodeForAccessToken(String code) {
        Response resp = new Response();
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(HEROKU_API_URL + '/oauth/tokens');
            request.setMethod('POST');
            request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
            request.setHeader('Content-Type', 'application/json');
            request.setBody('{"client": {"secret": "' + oauthApp.ClientSecret__c + '"},"grant": {"code": "' + code
                + '","type": "authorization_code"}}');
            HttpResponse herokuResponse = (new Http()).send(request);
            if (herokuResponse.getStatusCode() == 201){
                HerokuOAuthResponseWrp respWrp = 
                    (HerokuOAuthResponseWrp) JSON.deserialize(herokuResponse.getBody(), HerokuOAuthResponseWrp.class);
                resp.data.put('access_token', respWrp.access_token.token);
                resp.data.put('refresh_token', respWrp.refresh_token.token);
                resp.data.put('authorizationId', respWrp.authorization.id);
            } else {
                resp.error(herokuResponse.getStatus());
            }
        } catch (Exception ex) {
            resp.error(ex);
        }
        return resp;
    }

    private void refreshAccessToken() {
        this.accessToken = HerokuApi.refreshAccessToken(this.refreshToken);
    }

    public static String refreshAccessToken(String refreshToken) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(HEROKU_ID_URL + '/oauth/token');
        request.setMethod('POST');
        request.setBody('grant_type=refresh_token&refresh_token=' + refreshToken + 
            '&client_secret=' + oauthApp.ClientSecret__c);
        HttpResponse herokuResponse = (new Http()).send(request);
        if (herokuResponse.getStatusCode() == 200) {
            HerokuOAuthTokenRespWrp respWrp = 
                (HerokuOAuthTokenRespWrp) JSON.deserialize(herokuResponse.getBody(), HerokuOAuthTokenRespWrp.class);
            HerokuData.refreshedAccessToken = respWrp.access_token;
            return respWrp.access_token;
        } else {
            String errMsg = 'Heroku: ' + buildErrorMessage(herokuResponse);
            System.debug('JORA - herokuResponse.getStatusCode() ' + herokuResponse.getStatusCode());
            System.debug('JORA - herokuResponse.getStatusCode() ' + (herokuResponse.getStatusCode() == 401));
            CustomException ce = (herokuResponse.getStatusCode() == 401)
                ? AuthorizationException.build(errMsg)
                : CustomException.build(errMsg);
                
            if (herokuResponse.getStatusCode() == 401) {
                System.debug('JORA - is AuthorizationException ');
                throw AuthorizationException.build(errMsg);
            } else {
                System.debug('JORA - is CustomException ');
                throw CustomException.build(errMsg);
            }

            // CustomException ce = 
            //     ? AuthorizationException.build(errMsg)
            //     : CustomException.build(errMsg);
            // System.debug('JORA - is AuthorizationException ' + (((Object)ce) instanceOf AuthorizationException));
            // System.debug('JORA - is CustomException ' + (((Object)ce) instanceOf CustomException));
            // throw ce;
        }
    }

    public String requestUserName() {
        HttpResponse response = makeRequest('GET', '/account', null, 200);
        Map<String, Object> wrp = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (String) wrp.get('name');
    }

    public static Response requestAuthorization(String username, String password) {
        Response resp = new Response();
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(HEROKU_API_URL + '/oauth/authorizations');
            request.setMethod('POST');
            request.setBody('{"description":"' + 'Used for CI setup with \'PackagingWizard\' Salesforce app.' + '"}');
            request.setHeader('Authorization', 'Basic ' + 
                EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
            request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
            request.setHeader('Content-Type', 'application/json');

            HttpResponse herokuResponse = (new Http()).send(request);
            if (herokuResponse.getStatusCode() == 201) {
                HerokuAuthResponseWrp authResp = 
                    (HerokuAuthResponseWrp) JSON.deserialize(herokuResponse.getBody(), HerokuAuthResponseWrp.class);
                resp.data.put('token', authResp.access_token.token);
                resp.data.put('authorizationId', authResp.id);
            } else {
                resp.error(herokuResponse.getStatus());
            }
        } catch (Exception ex) {
            resp.error(ex);
        }
        return resp;
    }

    public static Response revokeAuthorization(String accessToken, String authorizationId) {
        Response resp = new Response();
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(HEROKU_API_URL + '/oauth/authorizations/' + authorizationId);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Accept', 'application/vnd.heroku+json; version=3');
            request.setHeader('Content-Type', 'application/json');
            HttpResponse herokuResponse = (new Http()).send(request);
            if (herokuResponse.getStatusCode() != 200) {
                resp.error(herokuResponse.getStatus());
            }
        } catch (Exception ex) {
            resp.error(ex);
        }
        return resp;
    }

    public HttpResponse makeRequest(String method, String endpoint, String body) {
        return makeRequest(method, endpoint, body, (Set<Integer>) null);
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Integer successCode) {
        return makeRequest(method, endpoint, body, new Set<Integer>{successCode});
    }

    public HttpResponse makeRequest(String method, String endpoint, String body, Set<Integer> successCodes) {
        HttpRequest request = basicHerokuRequest(method, endpoint);
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
            String errMsg = 'Heroku: ' + buildErrorMessage(response);
            throw (response.getStatusCode() == 401)
                ? AuthorizationException.build(errMsg)
                : CustomException.build(errMsg);
        }
    }

    public static String buildErrorMessage(HttpResponse response) {
        try{
            HerokuApiErrorWrp err = (HerokuApiErrorWrp)
                (HerokuApiErrorWrp) JSON.deserialize(response.getBody(), HerokuApiErrorWrp.class);
            return err.message;
        } catch (Exception ex) {
            return response.getStatus();
        }
    }

    // make POST request and returns Id value from response
    public String generalCreateRequest(String endpoint, String body) {
        String herokuResponseBody = makeRequest('POST', endpoint, body, 201).getBody();
        HerokuApiIdRespWrp resp = (HerokuApiIdRespWrp) JSON.deserialize(herokuResponseBody, HerokuApiIdRespWrp.class);
        return resp.id;
    }

    public String createApp(String appName) {
        HerokuApiGeneralCreateReq reqWrp = new HerokuApiGeneralCreateReq();
        reqWrp.name = appName;
        return generalCreateRequest('/apps', JSON.serialize(reqWrp));
    }

    public void deleteApp(String appId) {
        makeRequest('DELETE', '/apps/' + appId, null, new Set<Integer>{200, 404});
    }

    public String createPipeline(String pipelineName) {
        HerokuApiGeneralCreateReq reqWrp = new HerokuApiGeneralCreateReq();
        reqWrp.name = pipelineName;
        return generalCreateRequest('/pipelines', JSON.serialize(reqWrp));
    }

    public void deletePipeline(String pipelineId) {
        makeRequest('DELETE', '/pipelines/' + pipelineId, null, new Set<Integer>{200, 404});
    }

    public void addAppToPipeline(String appId, String pipelineId, String stage) {
        HerokuApiPipelineCouplingReq reqWrp = new HerokuApiPipelineCouplingReq();
        reqWrp.app = appId;
        reqWrp.pipeline = pipelineId;
        reqWrp.stage = stage;
        generalCreateRequest('/pipeline-couplings', JSON.serialize(reqWrp));
    }

    public void setBuildPack(String appId, String buildPackUrl) {
        HerokuApiSetBuildpackReqWrp reqWrp = new HerokuApiSetBuildpackReqWrp();
        HerokuApiSetBuildpackReqWrp.Updates upd = new HerokuApiSetBuildpackReqWrp.Updates();
        upd.buildpack = buildPackUrl;
        reqWrp.updates = new List<HerokuApiSetBuildpackReqWrp.Updates>{upd};
        makeRequest('PUT', '/apps/' + appId + '/buildpack-installations', JSON.serialize(reqWrp), 200);
    }

    public void setAppConfigVars(String appId, Map<String, Object> vars) {
        makeRequest('PATCH', '/apps/' + appId + '/config-vars', JSON.serialize(vars), 200);
    }
}
