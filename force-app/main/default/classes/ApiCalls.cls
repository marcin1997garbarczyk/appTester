public with sharing class ApiCalls extends fflib_SObjectDomain {

    public ApiCalls(List<Api_Call__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApiCalls(sObjectList);
        }
    }
    public static Map<Id, List<Api_Call__c>> generateApiRequestToListOfApiCallsMap(Set<Id> requestIds) {        
        Map<Id, List<Api_Call__c>> requestIdToApiCalls = new Map<Id, List<Api_Call__c>>();
        for(Api_Call__c apiCall : [SELECT Id, Api_Request__c, Url_Param__c, Api_Request__r.Id, Request_body__c, Response_Status_Code__c, Expected_Status_Code__c FROM Api_Call__c WHERE Api_Request__c IN: requestIds]) {
            if(requestIdToApiCalls.get(apiCall.Api_Request__c) == null) requestIdToApiCalls.put(apiCall.Api_Request__c, new List<Api_Call__c>()); 
            requestIdToApiCalls.get(apiCall.Api_Request__c).add(apiCall);
        }
        return requestIdToApiCalls;
    } 
}