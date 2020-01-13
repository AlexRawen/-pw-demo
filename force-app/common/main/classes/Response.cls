public with sharing class Response {
    public static final String STATUS_SUCCESS = 'success';
    public static final String STATUS_WARNING = 'warning';
    public static final String STATUS_INFO = 'info';
    public static final String STATUS_ERROR = 'error';

    public static final String SEVERITY_INFO = 'info';
    public static final String SEVERITY_SUCCESS = 'success';
    public static final String SEVERITY_WARNING = 'warning';
    public static final String SEVERITY_ERROR = 'error';

    public class ResponseMessage {
        @AuraEnabled
        public String severity;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String messageDetails;

        ResponseMessage(String message, String messageDetails, String severity) {
            this.severity = (severity != null) ? severity : SEVERITY_INFO;
            this.message = message;
            this.messageDetails = messageDetails;
        }
    }

    @AuraEnabled
    public String status = STATUS_SUCCESS;
    @AuraEnabled
    public ResponseMessage[] messages = new List<ResponseMessage>();
    @AuraEnabled
    public Map<String, Object> data = new Map<String, Object>();
    @AuraEnabled
    public String stackTrace;

    /* Set Statuses */
    public void error(Exception e) {
        this.error(e.getMessage());
        this.stackTrace = e.getStackTraceString();
    }

    public void error(String message) {
        this.error(message, null);
    }

    public void error(String message, String messageDetails) {
        this.error();
        this.addMessage(message, messageDetails, SEVERITY_ERROR);
    }

    public void error() {
        this.status = STATUS_ERROR;
    }

    public void warning(String message) {
        this.warning(message, null);
    }

    public void warning(String message, String messageDetails) {
        this.warning();
        this.addMessage(message, messageDetails, SEVERITY_WARNING);
    }

    public void warning() {
        this.status = STATUS_WARNING;
    }

    /* Check statuses */
    public Boolean isError() {
        return this.status == STATUS_ERROR;
    }

    public Boolean isSuccess() {
        return this.status == STATUS_SUCCESS;
    }

    public Boolean isWarning() {
        return this.status == STATUS_WARNING;
    }

    /* Messages */
    public void addMessage(String message, String severity) {
        this.addMessage(message, null, severity);
    }

    public void addMessage(String message, String messageDetails, String severity) {
        if (message == null) {
            return;
        }
        this.addMessage(new ResponseMessage(message, messageDetails, severity));
    }

    public void addMessage(ResponseMessage resMessage) {
        if (resMessage == null) {
            return;
        }
        this.messages.add(resMessage);
    }

    /* Data */
    public void setData(String key, Object data) {
        this.data.put(key, data);
    }

    public void setData(Map<String, String> data) {
        this.data.putAll(data);
    }

    public void setData(Response r) {
        this.data.putAll(r.data);
    }
}
