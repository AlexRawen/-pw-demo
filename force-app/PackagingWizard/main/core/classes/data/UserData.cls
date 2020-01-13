public inherited sharing class UserData {

    public static Boolean isUserExists(String username) {
        List<User> users = [
                                SELECT Id
                                FROM User 
                                WHERE Username = :username 
                                LIMIT 1
                            ];
        return !users.isEmpty();
    }
}
