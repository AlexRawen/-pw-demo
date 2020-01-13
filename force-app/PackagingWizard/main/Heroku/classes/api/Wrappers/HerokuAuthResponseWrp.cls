public with sharing class HerokuAuthResponseWrp {

	public Access_token access_token;
	public Object client;
	public String created_at;
	public String description;
	public Object grant;
	public String id;
	public Object refresh_token;
	public Object session;
	public List<String> scope;
	public String updated_at;
	public User user;

	public class Access_token {
		public Object expires_in;
		public String id;
		public String token;
	}

	public class User {
		public String id;
		public String email;
		public String full_name;
	}
}
