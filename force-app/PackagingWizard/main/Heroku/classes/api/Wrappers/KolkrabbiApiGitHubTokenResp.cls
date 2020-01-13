public inherited sharing class KolkrabbiApiGitHubTokenResp {

    public String created_at;
    public Github github;
    public Heroku heroku;
    public String id;
    public String updated_at;

    public class Github {
        public String token;
        public Integer user_id;
    }

    public class Heroku {
        public String user_id;
    }

}