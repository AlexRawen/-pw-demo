public inherited sharing class SalesforceOrgsData {
    
    public static final String ORG_DEVHUB = 'devhub';
    public static final String ORG_QA = 'qa';
    public static final String ORG_STAGING = 'staging';

    public static final List<String> ORGS = new List<String>{
        ORG_DEVHUB, ORG_QA, ORG_STAGING
    };

    public static SalesforceOrgCredentials__c getCredentialsByOrgName(String orgName) {
        return SalesforceOrgCredentials__c.getInstance(orgName.toLowerCase());
    }

    public static Map<String, SalesforceOrgCredentials__c> getAllOrgsCredentials() {
        return SalesforceOrgCredentials__c.getAll();
    }

    public static void storeCredentialsForOrg(
        String orgName, String username, String password, String token, Boolean isSandbox
    ) {
        orgName = orgName.toLowerCase();
        SalesforceOrgCredentials__c creds = getCredentialsByOrgName(orgName);
        if (creds == null) {
            creds = new SalesforceOrgCredentials__c(Name = orgName);
        }
        creds.Username__c = username;
        creds.Password__c = password; 
        creds.SecurityToken__c = token; 
        creds.IsSandbox__c = isSandbox;
        upsert creds;
    }

    public static void deleteCredentialsForOrg(String orgName) {
        SalesforceOrgCredentials__c creds = getCredentialsByOrgName(orgName);
        if (creds != null) {
            delete creds;
        }
    }

    public static String getManagedPackagePrefix() { 
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        return (setts != null) ? setts.ManagedPackagePrefix__c : null;
    }

    public static void setManagedPackagePrefix(String managedPackagePrefix) { 
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        if (setts != null && setts.Id != null) {
            setts.ManagedPackagePrefix__c = managedPackagePrefix;
            update setts;
        } else {
            insert new PackagingWizardSettings__c(
                ManagedPackagePrefix__c = managedPackagePrefix
            );
        }
    }

    public static String getPackageName() { 
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        return (setts != null) ? setts.PackageName__c : null;
    }

    public static void setPackageName(String packageName) { 
        PackagingWizardSettings__c setts = PackagingWizardSettings__c.getOrgDefaults();
        if (setts != null && setts.Id != null) {
            setts.PackageName__c = packageName;
            update setts;
        } else {
            insert new PackagingWizardSettings__c(
                PackageName__c = packageName
            );
        }
    }

}