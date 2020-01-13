public inherited sharing class AuthorizationException extends CustomException{
    public static AuthorizationException build(String msg) {
        AuthorizationException ex = new AuthorizationException(msg);
        ex.stackTrace = new DmlException().getStackTraceString().replaceFirst('(?m)(.*\\n){1}?', '');
        return ex;
    }
}
