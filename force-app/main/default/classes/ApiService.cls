public with sharing class ApiService {

    
    @InvocableMethod(callout=true label='Test Api under Account')    
    public static List<String> testxApiUnderAccountService(List<Id> recordId) {
        try{
            Accounts accounts = new Accounts([SELECT Id FROM Account WHERE Id IN: recordId]);
            accounts.testApiForAccount(); 
            return new List<String>{'Test run correct, go to related list and check api stability'};
        } catch (Exception e) {
            return new List<String>{'Some errors stop running test. Error Message: '+e.getMessage()};
        }
    } 
    // @InvocableMethod(callout=true label='Test Api under Account')    
    // public static void testApiUnderAccountService(List<Id> recordId) {
    //     try{
    //         Accounts accounts = new Accounts([SELECT Id FROM Account WHERE Id IN: recordId]);
    //         accounts.testApiForAccount(); 
    //         return 'Test run correct, go to related list and check api stability';
    //     } catch (Exception e) {
    //         return 'Some errors stop running test. Error Message: '+e.getMessage();
    //     }
    // } 
}
