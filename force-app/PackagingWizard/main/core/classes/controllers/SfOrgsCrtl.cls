public with sharing class SfOrgsCrtl {

    @AuraEnabled
    public static Response getAuthorizationsInfo() {
        Response resp = new Response();
        try {
            resp.data = SalesforceOrgsSvc.getAuthorizationsInfo();
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled
    public static Response revokeOrgAuthorization(String request) {
        Response resp = new Response();
        try {
            RevokeOrgAuthRequest req = (RevokeOrgAuthRequest) JSON.deserialize(request, RevokeOrgAuthRequest.class);
            req.validate();

            HerokuSvc.updateOrgCredsInApps(req.orgName, null, null, null, null);
            SalesforceOrgsData.deleteCredentialsForOrg(req.orgName);
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public class RevokeOrgAuthRequest implements Validatable{
        public String orgName;

        public void validate() {
            validateOrgName(this.orgName);
        }
    }

    public static void validateOrgName(String orgName) {
        if(!SalesforceOrgsData.ORGS.contains(orgName.toLowerCase())) {
            throw new ValidationException('Unrecognized org type : \'' + orgName + '\'.');
        }
    }

    public class OrgAuthRequest implements Validatable{
        public String orgName;
        public Boolean isSandbox;
        public String username;
        public String password;
        public String token;

        public void validate() {
            validateOrgName(this.orgName);
            if(String.isBlank(username)) {
                throw new ValidationException('Username is empty.');
            }
            if (orgName == SalesforceOrgsData.ORG_DEVHUB && !UserData.isUserExists(username)) {
                throw new ValidationException('No \'' + username + '\' user in current DevHub org.');
            }
            if(String.isBlank(password)) {
                throw new ValidationException('Password is empty.');
            }
            if(String.isBlank(token)) {
                throw new ValidationException('Security token is empty.');
            }
        }
    }

    @AuraEnabled
    public static Response authorizeOrg(String request) {
        Response resp = new Response();
        try {
            OrgAuthRequest req = (OrgAuthRequest) JSON.deserialize(request, OrgAuthRequest.class);

            SalesforceOrgsSvc.validateOrgCredentials(req.username, req.password, req.token, req.isSandbox);
            HerokuSvc.updateOrgCredsInApps(
                req.orgName, req.username, req.password, req.token, req.isSandbox);
            SalesforceOrgsData.storeCredentialsForOrg(
                req.orgName, req.username, req.password, req.token, req.isSandbox);
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    @AuraEnabled(cacheable=true)
    public static Response getOrgInfo() {
        Response res = new Response();
        try {
            res.data.put('isDevHub', Env.isDevHub());
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    @AuraEnabled
    public static Response getLinkedNamespaces() {
        Response res = new Response();
        try {
            if (Env.isDevHub()) {
                res.data.put('namespaces', SalesforceOrgsSvc.getLinkedNamespaces());
            } else {
                res.error('Current org is not a DevHub.');
            }
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    @AuraEnabled
    public static Response getPackageName() {
        Response res = new Response();
        try {
            res.data.put('name', SalesforceOrgsData.getPackageName());
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    @AuraEnabled
    public static Response setPackageName(String request) {
        Response res = new Response();
        try {
            PackageNameRequest reqWrp = (PackageNameRequest) 
                JSON.deserialize(request, PackageNameRequest.class);
            reqWrp.validate();

            Map<String, String> configVars = new Map<String, String>{
                HerokuSvc.CONFIG_SFDX_PACKAGE_NAME => reqWrp.name
            };

            HerokuSvc.setAppConfigVars(HerokuSvc.AppStage.QA, configVars);
            HerokuSvc.setAppConfigVars(HerokuSvc.AppStage.STAGING, configVars);
            SalesforceOrgsData.setPackageName(reqWrp.name);
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    public class PackageNameRequest implements Validatable{
        public String name;

        public void validate() {
            if (String.isEmpty(name)) {
                throw new ValidationException('\'Unlocked Package Name\' is empty.');
            }
        }
    }

    @AuraEnabled
    public static Response getManagedPackagePrefix() {
        Response res = new Response();
        try {
            res.data.put('name', SalesforceOrgsData.getManagedPackagePrefix());
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    @AuraEnabled
    public static Response selectManagedPackagePrefix(String request) {
        Response res = new Response();
        try {
            ManagedPackagePrefixRequest reqWrp = (ManagedPackagePrefixRequest) 
                JSON.deserialize(request, ManagedPackagePrefixRequest.class);
            reqWrp.validate();

            Map<String, String> configVars = new Map<String, String>{
                HerokuSvc.CONFIG_PACKAGE_NAMESPACE => reqWrp.name
            };

            HerokuSvc.setAppConfigVars(HerokuSvc.AppStage.STAGING, configVars);
            SalesforceOrgsData.setManagedPackagePrefix(reqWrp.name);
        } catch (Exception ex) {
            res.error(ex);
        }
        return res;
    }

    public class ManagedPackagePrefixRequest implements Validatable{
        public String name;

        public void validate() {
            if (String.isEmpty(name)) {
                throw new ValidationException('\'Managed Package Prefix\' is empty.');
            }
            if (!SalesforceOrgsSvc.getLinkedNamespaces().contains(name)) {
                throw new ValidationException('Unlinked \'' + name + '\' prefix selected.');
            }
        }
    }

}
