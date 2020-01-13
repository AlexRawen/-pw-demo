public inherited sharing class GitHubApiErorrRespWrp {

	public String message;
	public List<Error> errors;

	public class Error {
		public String resource;
		public String field;
		public String code;
		public String message;
	}

}
