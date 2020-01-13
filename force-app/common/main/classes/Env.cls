public with sharing class Env {

    private static Boolean isSandbox;
    public static Boolean isSandbox() {
        if (isSandbox == null) {
            Organization org = [SELECT IsSandbox FROM Organization];
            isSandbox = org.IsSandbox;
        }
        return isSandbox;
    }

    private static Boolean isDevHub;
    public static Boolean isDevHub() {
        if (isDevHub == null) {
            isDevHub =  Schema.getGlobalDescribe().containsKey('NamespaceRegistry');
        }
        return isDevHub;
    }
}
