public with sharing class SalesforceOrgsSvc {
    
    public static Map<String, OrgAuthInfo> getAuthorizationsInfo() {
        Map<String, OrgAuthInfo> orgAuthInfoMap = new Map<String, OrgAuthInfo>();

        Map<String, SalesforceOrgCredentials__c> creds = SalesforceOrgsData.getAllOrgsCredentials();
        for (String orgName : SalesforceOrgsData.ORGS) {
            SalesforceOrgCredentials__c orgCreds = creds.get(orgName);
            if (orgCreds != null && String.isNotBlank(orgCreds.Username__c)) {
                orgAuthInfoMap.put(orgName, new OrgAuthInfo(orgCreds.Username__c));
            } else {
                orgAuthInfoMap.put(orgName, new OrgAuthInfo());
            }
        }

        return orgAuthInfoMap;
    }

    public class OrgAuthInfo {
        @AuraEnabled public Boolean isAuthorized;
        @AuraEnabled public String userName;

        public OrgAuthInfo() {
            this.isAuthorized = false;
        }

        public OrgAuthInfo(String userName) {
            this.isAuthorized = true;
            this.userName = userName;
        }
    }

    // validte via SOAP login call with provaided creds
    public static void validateOrgCredentials(
        String username, String password, String token, Boolean isSandbox
    ) {
        SfPartnerSoapAPI.Soap psApi = new SfPartnerSoapAPI.Soap();
        if (isSandbox) {
            psApi.endpoint_x = SfPartnerSoapAPI.TEST_ENDPOINT;
        }
        try{
            // try to login with provided credentials via Partner SOAP API
            SfPartnerSoapAPI.LoginResult loginResult = psApi.login(username, password + token);
        } catch (CalloutException ex) {
            if (ex.getMessage().contains(SfPartnerSoapAPI.INVALID_LOGIN)) {
                throw new ValidationException('Unable to login with provided credentials.');
            } else {
                throw ex;
            }
        }
    }

    public static List<String> getLinkedNamespaces() {
        List<String> linkedNamespaces = new List<String>();
        if (Env.isDevHub()) {
            for(SObject reg : Database.query('SELECT NamespacePrefix FROM NamespaceRegistry')) {
                linkedNamespaces.add(String.valueOf(reg.get('NamespacePrefix')));
            }
        }
        return linkedNamespaces;
    }

}
