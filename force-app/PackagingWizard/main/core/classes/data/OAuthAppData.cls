public inherited sharing class OAuthAppData {

    public static OAuthApp__mdt getOAuthAppByDevName(String developerName) {
        return [
            SELECT ClientId__c, ClientSecret__c, DeveloperName
            FROM OAuthApp__mdt WHERE DeveloperName = :developerName
        ];
    }

}
