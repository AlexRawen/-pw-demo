public with sharing class HerokuSvc {
    public static final String PIPELINE_NAME = 'packaging-wizard-ci';

    public static final String CONFIG_SFDX_PACKAGE_NAME = 'SFDX_PACKAGE_NAME';
    public static final String CONFIG_PACKAGE_NAMESPACE = 'PACKAGE_NAMESPACE';
    public static final String CONFIG_STAGE = 'STAGE';

    public static final String CONFIG_DEV_HUB_USERNAME = 'DEV_HUB_USERNAME';
    public static final String CONFIG_DEV_HUB_PASSWORD = 'DEV_HUB_PASSWORD';
    public static final String CONFIG_DEV_HUB_TOKEN = 'DEV_HUB_TOKEN';

    public static final String CONFIG_SF_ORG_IS_SANDBOX = 'SF_ORG_IS_SANDBOX';
    public static final String CONFIG_SF_ORG_USERNAME = 'SF_ORG_USERNAME';
    public static final String CONFIG_SF_ORG_PASSWORD = 'SF_ORG_PASSWORD';
    public static final String CONFIG_SF_ORG_TOKEN = 'SF_ORG_TOKEN';

    public static Boolean isAuthorized() {
        return String.isNotBlank(HerokuData.getAccessToken());
    }

    public static String getOAuthUrl() {
        return HerokuApi.getOAuthEndpointUrl();
    }

    public static void exchangeCodeForAccessToken(String code, String state) {
        Response accessTokenResponse = HerokuApi.exchangeCodeForAccessToken(code);
        if (!accessTokenResponse.isSuccess()) {
            throw new CustomException('Access token not exchanged');
        }
        String accessToken = (String) accessTokenResponse.data.get('access_token');
        String refreshToken = (String) accessTokenResponse.data.get('refresh_token');
        String authorizationId = (String) accessTokenResponse.data.get('authorizationId');

        HerokuApi herokuApi = new HerokuApi(accessToken, refreshToken);
        String userName = herokuApi.requestUserName();

        HerokuData.storeDirectAuthorization(accessToken, authorizationId);
        HerokuData.storeWebAuthorizationInfo(accessToken, refreshToken, userName);
    }

    public static void refreshAccessToken() {
        HerokuApi api = new HerokuApi();
        String refreshedAccessToken = HerokuApi.refreshAccessToken(HerokuData.getRefreshToken());
        HerokuData.storeAccessToken(refreshedAccessToken);
    }

    public enum AppStage {
        QA,
        STAGING
    }

    public static AppGitHubInfo getAppInfo(AppStage stage) {
        String appId = HerokuData.getAppId(stage);
        if (String.isBlank(appId)) {
            return null;
        }

        KolkrabbiApi api = new KolkrabbiApi(HerokuData.getAccessToken());
        KolkrabbiApiGitHubInfoResp resp = api.getAppInfo(appId);

        AppGitHubInfo info = new AppGitHubInfo();
        if (resp != null) {
            info.repo = resp.repo;
            if (resp.auto_deploy == true) {
                info.branch = resp.branch;
            }
        }
        return info;
    }

    public class AppGitHubInfo {
        public String repo;
        public String branch;
    }

    public static String getGitHubAccessToken() {
        KolkrabbiApi api = new KolkrabbiApi(HerokuData.getAccessToken());
        return api.getGitHubAccessToken();
    }

    public static String generateAppName(String managedPrefix, AppStage stage) {
        // app name length limit - 30 characters

        String stageSuffix = stage.name().left(2);

        String orgIdSuffix = UserInfo.getOrganizationId();
        // 8 = 30 - (stageSuffix.length()) - 2 * ('-'.length()) - orgIdSuffix.length() = 30 - 2 - 2 - 18
        if (managedPrefix.length() > 8) {
            // remove '00D' org sobject prefix: 00d3o0000008c9vuaq -> ___3o0000008c9vuaq
            orgIdSuffix = orgIdSuffix.right(15);
        }
        if (managedPrefix.length() > 11) {
            // remove few additional characters (usually they are '0'): 3o0000008c9vuaq -> 3o008c9vuaq
            orgIdSuffix = orgIdSuffix.left(3) + orgIdSuffix.right(8);
        }

        String appName = managedPrefix + '-' + stageSuffix + '-' + orgIdSuffix;

        return appName.replace('_', '-').toLowerCase();
    }

    public static void createAppsAndPipeline() {
        HerokuApi api = new HerokuApi();

        String qaAppId = HerokuData.getAppId(AppStage.QA);
        String stagingAppId = HerokuData.getAppId(AppStage.STAGING);
        String pipelineId = HerokuData.getPipelineId();

        if (String.isBlank(qaAppId)) {
            // create new app
            qaAppId = api.createApp(generateAppName(SalesforceOrgsData.getManagedPackagePrefix(), AppStage.QA));
            api.setBuildPack(qaAppId, 'https://bitbucket.org/aquiva/aquiva-sfdx-heroku-buildpack');
            api.setAppConfigVars(qaAppId, buildConfigVars(AppStage.QA));
            if (String.isNotBlank(pipelineId)) {
                // add app to existing pipline
                api.addAppToPipeline(qaAppId, pipelineId, HerokuApi.PIPELINE_STAGE_DEVELOPMENT);
            }
        }

        if (String.isBlank(stagingAppId)) {
            // create new app
            stagingAppId = api.createApp(
                generateAppName(SalesforceOrgsData.getManagedPackagePrefix(), AppStage.STAGING)
            );
            api.setBuildPack(stagingAppId, 'https://bitbucket.org/aquiva/aquiva-sfdx-heroku-buildpack');
            api.setAppConfigVars(stagingAppId, buildConfigVars(AppStage.STAGING));
            if (String.isNotBlank(pipelineId)) {
                // add app to existing pipline
                api.addAppToPipeline(stagingAppId, pipelineId, HerokuApi.PIPELINE_STAGE_STAGING);
            }
        }

        if (String.isBlank(pipelineId)) {
            // create new pipeline
            pipelineId = api.createPipeline(PIPELINE_NAME);
            // add apps to a new pipline
            api.addAppToPipeline(qaAppId, pipelineId, HerokuApi.PIPELINE_STAGE_DEVELOPMENT);
            api.addAppToPipeline(stagingAppId, pipelineId, HerokuApi.PIPELINE_STAGE_STAGING);
        }

        HerokuData.storeAppsAndPipelineIds(qaAppId, stagingAppId, pipelineId);
    }

    // returns true if specified app exists and configs are set
    public static Boolean setAppConfigVars(AppStage stage, Map<String, Object> vars) {
        String appId = HerokuData.getAppId(stage);
        if (String.isNotBlank(appId)) {
            HerokuApi api = new HerokuApi();
            api.setAppConfigVars(appId, vars);
            return true;
        } else {
            return false;
        }
    }

    private static Map<String, Object> buildConfigVars(AppStage stage) {
        Map<String, Object> vars = new Map<String, Object>();

        SalesforceOrgCredentials__c devHubCreds = SalesforceOrgsData.getCredentialsByOrgName(
            SalesforceOrgsData.ORG_DEVHUB
        );
        if (devHubCreds != null) {
            vars.putAll(
                buildConfigVarsForDevHubOrgCreds(
                    devHubCreds.Username__c,
                    devHubCreds.Password__c,
                    devHubCreds.SecurityToken__c
                ));
        }

        SalesforceOrgCredentials__c sfOrgCreds;
        String configStage;

        switch on stage {
            when QA {
                sfOrgCreds = SalesforceOrgsData.getCredentialsByOrgName(SalesforceOrgsData.ORG_QA);
                configStage = 'DEV';
            }
            when STAGING {
                sfOrgCreds = SalesforceOrgsData.getCredentialsByOrgName(SalesforceOrgsData.ORG_STAGING);
                configStage = 'STAGING';
                vars.put(CONFIG_PACKAGE_NAMESPACE, SalesforceOrgsData.getManagedPackagePrefix());
            }
        }

        if (sfOrgCreds != null) {
            vars.putAll(
                buildConfigVarsForSfOrgCreds(
                    sfOrgCreds.Username__c,
                    sfOrgCreds.Password__c,
                    sfOrgCreds.SecurityToken__c,
                    sfOrgCreds.IsSandbox__c
                ));
        }

        vars.put(CONFIG_SFDX_PACKAGE_NAME, SalesforceOrgsData.getPackageName());
        vars.put(CONFIG_STAGE, configStage);

        return vars;
    }

    public static Map<String, String> buildConfigVarsForDevHubOrgCreds(
        String username, String password, String token
    ) {
        return new Map<String, String>{
            CONFIG_DEV_HUB_USERNAME => username,
            CONFIG_DEV_HUB_PASSWORD => password,
            CONFIG_DEV_HUB_TOKEN => token
        };
    }

    public static Map<String, Object> buildConfigVarsForSfOrgCreds(
        String username, String password, String token, Boolean isSandbox
    ) {
        return new Map<String, Object>{
            CONFIG_SF_ORG_USERNAME => username,
            CONFIG_SF_ORG_PASSWORD => password,
            CONFIG_SF_ORG_TOKEN => token,
            CONFIG_SF_ORG_IS_SANDBOX => isSandbox
        };
    }

    public static void updateOrgCredsInApps(
        String orgName, String username, String password, String token, Boolean isSandbox
    ) {
        if (orgName == SalesforceOrgsData.ORG_DEVHUB) {
            Map<String, Object> configWithDevHubCreds = buildConfigVarsForDevHubOrgCreds(username, password, token);
            setAppConfigVars(AppStage.QA, configWithDevHubCreds);
            setAppConfigVars(AppStage.STAGING, configWithDevHubCreds);

        } else {
            Map<String, Object> configWithSfOrgCreds = 
                buildConfigVarsForSfOrgCreds(username, password, token, isSandbox);

            if (orgName == SalesforceOrgsData.ORG_QA) {
                setAppConfigVars(AppStage.QA, configWithSfOrgCreds);
            } else if (orgName == SalesforceOrgsData.ORG_STAGING) {
                setAppConfigVars(AppStage.STAGING, configWithSfOrgCreds);
            }
        }
    }

    public static void removeAppsAndPipeline() {
        HerokuApi api = new HerokuApi();

        String pipelineId = HerokuData.getPipelineId();
        if (String.isNotBlank(pipelineId)) {
            api.deletePipeline(pipelineId);
        }

        String qaAppId = HerokuData.getAppId(AppStage.QA);
        if (String.isNotBlank(qaAppId)) {
            api.deleteApp(qaAppId);
        }

        String stagingAppId = HerokuData.getAppId(AppStage.STAGING);
        if (String.isNotBlank(stagingAppId)) {
            api.deleteApp(stagingAppId);
        }

        HerokuData.storeAppsAndPipelineIds(null, null, null);
    }

    public static void selectRepository(String repoFullName) {
        KolkrabbiApi api = new KolkrabbiApi(HerokuData.getAccessToken());

        String qaAppId = HerokuData.getAppId(AppStage.QA);
        api.removeAppRepository(qaAppId);
        api.setAppRepository(qaAppId, repoFullName);

        String stagingAppId = HerokuData.getAppId(AppStage.STAGING);
        api.removeAppRepository(stagingAppId);
        api.setAppRepository(stagingAppId, repoFullName);
    }

    public static void selectAppBranch(AppStage stage, String branchName) {
        KolkrabbiApi api = new KolkrabbiApi(HerokuData.getAccessToken());

        String appId = HerokuData.getAppId(stage);
        api.setAppBranch(appId, branchName);
    }

    public static String getConnectGitHubUrl() {
        String qaAppId = HerokuData.getAppId(AppStage.QA);
        if (String.isNotBlank(qaAppId)) {
            return HerokuApi.HEROKU_DASHBOARD_URL + '/' + qaAppId + '/deploy/github';
        } else {
            return null;
        }
    }

    public static Boolean isPipelineAndAppsExistsInSFDC() {
        String pipelineId = HerokuData.getPipelineId();
        String qaAppId = HerokuData.getAppId(AppStage.QA);
        String stagingAppId = HerokuData.getAppId(AppStage.Staging);

        return String.isNotBlank(pipelineId)
            && String.isNotBlank(stagingAppId)
            && String.isNotBlank(qaAppId);
    }

    public static String getPipelineUrl() {
        String pipelineId = HerokuData.getPipelineId();
        if (String.isNotBlank(pipelineId)) {
            return HerokuApi.HEROKU_DASHBOARD_URL + '/pipelines/' + pipelineId;
        } else {
            return null;
        }
    }

    public static String getUserName() {
        return (new HerokuApi()).requestUserName();
    }
}
