public inherited sharing class KolkrabbiApiGitHubInfoResp {

	public App app;
	public Pull_requests pull_requests;
	public String app_id;
	public String id;
	public Object parent;
	public Boolean auto_deploy;
	public Boolean wait_for_ci;
	public String branch;
	public String created_at;
	public Owner owner;
	public Object pull_request;
	public String repo;
	public Integer repo_id;
	public String updated_at;

	public class App {
		public String id;
	}

	public class Pull_requests {
		public Boolean enabled;
		public Boolean auto_deploy;
	}

	public class Owner {
		public String id;
		public Heroku heroku;
		public Github github;
	}

	public class Heroku {
		public String user_id;
	}

	public class Github {
		public Integer user_id;
	}

}