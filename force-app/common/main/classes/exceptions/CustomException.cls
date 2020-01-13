public virtual with sharing class CustomException extends Exception{

    protected String stackTrace;

    public static CustomException build(String msg) {
        CustomException ex = new CustomException(msg);
        ex.stackTrace = new DmlException().getStackTraceString().replaceFirst('(?m)(.*\\n){1}?', '');
        return ex;
    }

    //Valid levels
    public static final String LEVEL_USER = 'User';				//Result relates directly to user actions -- end user can see details
    public static final String LEVEL_BUSINESS = 'Business';		//Result relates to business rules -- end user can see details
    public static final String LEVEL_INTERNAL = 'Internal';		//Internal -- details should be shielded from end user
    public static final Set<String> LEVELS_ALL = new Set<String>{LEVEL_USER, LEVEL_BUSINESS, LEVEL_INTERNAL};
    public static final Set<String> LEVELS_SHIELD = new Set<String>{LEVEL_INTERNAL};

    public String level;

    //Decide whether the result details should be shown to the user, and if not, log and make generic result.
    public static String shieldError(Exception ex) {

        // AqEnv.DebugMode != true && 
        if (ex instanceof CustomException && !LEVELS_SHIELD.contains(((CustomException)ex).level)) {
            return ex.getMessage();
        } else {
            Log__c errLog = Log.logException(ex);
            return String.format('An unexpected error has occurred, reference Id: {0}.', new List<String>{errLog.Id});
        }
    }

    // At the current state of salesforce custom exceptions does not return stack trace.
    // This workaround was implemented to be able to get stack trace even from custom exceptions.
    public override String getStackTraceString() {
        return this.stackTrace;
    }

}
