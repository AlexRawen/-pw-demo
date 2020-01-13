public inherited sharing class HerokuData {

    public static String refreshedAccessToken;
    public static String getAccessToken() {
        if (refreshedAccessToken == null) {
            PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
            return (setts != null) ? setts.HerokuAccessToken__c : null;
        } else {
            return refreshedAccessToken;
        } 
    }

    public static String getRefreshToken() {
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        return (setts != null) ? setts.HerokuRefreshToken__c : null;
    }

    public static String getAuthorizedUserName() {
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        return (setts != null) ? setts.HerokuUserName__c : null;
    }

    public static String getAuthorizationId() {
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        return (setts != null) ? setts.HerokuAuthorizationId__c : null;
    }

    public static void storeAccessToken(String token) {
        PackagingWizardSettings__c setts = new PackagingWizardSettings__c();
        setts.Id = PackagingWizardSettings__c.getOrgDefaults().Id;
        setts.HerokuAccessToken__c = token;
        upsert setts;
    }

    public static void storeRefreshedAccessToken() {
        if (refreshedAccessToken != null) {
            PackagingWizardSettings__c setts = new PackagingWizardSettings__c();
            setts.Id = PackagingWizardSettings__c.getOrgDefaults().Id;
            setts.HerokuAccessToken__c = refreshedAccessToken;
            upsert setts;
        }
    }

    public static void storeDirectAuthorization(String token, String authorizationId) {
        PackagingWizardSettings__c setts = new PackagingWizardSettings__c();
        setts.Id = PackagingWizardSettings__c.getOrgDefaults().Id;
        setts.HerokuAccessToken__c = token;
        setts.HerokuAuthorizationId__c = authorizationId;
        upsert setts;
    }

    public static void storeWebAuthorizationInfo(String token, String refreshToken, String userName) {
        PackagingWizardSettings__c setts = new PackagingWizardSettings__c();
        setts.Id = PackagingWizardSettings__c.getOrgDefaults().Id;
        setts.HerokuAccessToken__c = token;
        setts.HerokuRefreshToken__c = refreshToken;
        setts.HerokuUserName__c = userName;
        upsert setts;
    }

    public static void deleteAuthorization() {
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        if (setts != null && (String.isNotBlank(setts.HerokuAccessToken__c))) {
            setts.HerokuAccessToken__c = null;
            setts.HerokuRefreshToken__c = null;
            setts.HerokuAuthorizationId__c = null;
            setts.HerokuUserName__c = null;
            update setts;
        }
    }

    public static String getAppId(HerokuSvc.AppStage stage) {
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        if (setts == null) {
            return null;
        } else {
            if (stage == HerokuSvc.AppStage.QA) {
                return setts.HerokuQaAppId__c;
            } else {
                return setts.HerokuStagingAppId__c;
            }
        }
    }

    public static String getPipelineId() {
        return PackagingWizardSettings__c.getOrgDefaults().HerokuPipelineId__c;
    }

    public static void storeAppsAndPipelineIds(String qaAppId, String staginAppId, String pipelineId) {
        PackagingWizardSettings__c setts = new PackagingWizardSettings__c();
        setts.Id = PackagingWizardSettings__c.getOrgDefaults().Id;
        setts.HerokuQaAppId__c = qaAppId;
        setts.HerokuStagingAppId__c = staginAppId;
        setts.HerokuPipelineId__c = pipelineId;
        upsert setts;
    }
}
