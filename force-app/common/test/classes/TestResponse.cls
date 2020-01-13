@isTest
private with sharing class TestResponse {
    
    @isTest
    private static void errorFromException() {
        Response resp = new Response();

        Test.startTest();

            try{
                Integer x = 1 / 0;
            } catch (Exception ex) {
                resp.error(ex);
            }

        Test.stopTest();

        System.assert(resp.isError(), 'Response should have an error status.');
        System.assert(String.isNotBlank(resp.stackTrace), 'Response should heve some stack trace.');
    }
    
    @isTest
    private static void testAddMessages() {
        Response resp = new Response();

        System.assertEquals(0, resp.messages.size(), 'Initially, Response should not have any ResponseMessage');

        Test.startTest();

            resp.addMessage('test', Response.SEVERITY_INFO);

        Test.stopTest();

        System.assertEquals(1, resp.messages.size(), 'Response should have one ResponseMessage');
    }
    
    @isTest
    private static void testData() {
        Response resp1 = new Response();
        Response resp2 = new Response();
        String testDataKey = 'test';

        Test.startTest();

            resp1.setData(testDataKey, 42);
            resp2.setData(resp1);

        Test.stopTest();

        System.assertEquals(42, resp1.data.get(testDataKey), 'Test data is not added to Response');
        System.assertEquals(42, resp2.data.get(testDataKey), 'Test data is not added to Response');
    }
    
    @isTest
    private static void testWarning() {
        Response resp = new Response();

        System.assert(resp.isSuccess(), 'Initially, Response should have a success status.');
        
        Test.startTest();

            resp.warning('test warning message');

        Test.stopTest();

        System.assert(resp.isWarning(), 'Response should have a warning status');
    }
}
