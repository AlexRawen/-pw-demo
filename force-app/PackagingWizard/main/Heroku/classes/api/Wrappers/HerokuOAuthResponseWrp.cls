public with sharing class HerokuOAuthResponseWrp {

	public Authorization authorization;
	public Access_token access_token;
	public String created_at;
	public Refresh_token refresh_token;
	public Session session;
	public String updated_at;
	public Authorization user;

	public class Access_token {
		public Integer expires_in;
		public String id;
		public String token;
	}

	public class Authorization {
		public String id;
	}

	public class Refresh_token {
		public Integer expires_in;
		public String id;
		public String token;
	}

	public class Session {
		public String id;
	}
}