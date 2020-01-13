public with sharing class Log {

    public static Log__c logException(Exception ex) {
        Log__c log = new Log__c();
        log.Message__c = ex.getMessage();
        log.Details__c = ex.getStackTraceString();
        log.Log_Date__c = System.now();
        insert log;
        return log;
    }

}
