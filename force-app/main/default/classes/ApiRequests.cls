public with sharing class ApiRequests extends fflib_SObjectDomain {

    public ApiRequests(List<Api_Request__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApiRequests(sObjectList);
        }
    }

    public void callToExternalSystem(Boolean callForAuthorization) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { Api_Call__c.SObjectType, Api_Request__c.SObjectType, External_System__c.SObjectType });

        Map<Id, Map<Id, HttpRequest>> externalSystemToApiRequest = new Map<Id, Map<Id, HttpRequest>>();
        Map<Id, Api_Call__c> apiCallIdToObj = new Map<Id, Api_Call__c>();
        Map<Id, SObject> apiRequestsMap = new Map<Id, SObject>(Records);
        Map<Id, List<Api_Call__c>> requestIdToApiCall = ApiCalls.getApiCallsWithApiRequestIdMap(apiRequestsMap.keySet());
        Boolean performCommit = false;

        for(Api_Request__c apiRequest : (List<Api_Request__c>) Records) {
            for(Api_Call__c apiCall: requestIdToApiCall.get(apiRequest.Id)) {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(apiRequest.Endpoint__c);
                req.setMethod(apiRequest.Type__c);
                if(externalSystemToApiRequest.get(apiRequest.External_System__c) == null) externalSystemToApiRequest.put(apiRequest.External_System__c, new Map<Id, HttpRequest>());
                externalSystemToApiRequest.get(apiRequest.External_System__c).put(apiCall.Id, req);
                apiCallIdToObj.put(apiCall.Id, apiCall);
                if(apiRequest.Type__c != 'GET') {
                    req.setBody(apiCall.Request_Body__c);
                }
            }
        }

        for(Id externalSystemId : externalSystemToApiRequest.keySet()) {
            for(Id apiCallId : externalSystemToApiRequest.get(externalSystemId).keySet()) {
                Map<Id, HttpRequest> apiCallTohttpReq = externalSystemToApiRequest.get(apiCallId);
                HttpRequest httpReq = externalSystemToApiRequest.get(externalSystemId).get(apiCallId);

                Http http = new Http();
                HTTPResponse res = http.send(httpReq);
                String responseBody = res.getBody();
                String responseStatus = res.getStatus();
                String responseStatusCode = String.valueOf(res.getStatusCode());
                
                Api_Call__c apiCall = new Api_Call__c();
                apiCall.Response_status__c = responseStatus;
                apiCall.Response_status_code__c = responseStatusCode;
                apiCall.Response_message__c = responseBody;
                apiCall.Id = apiCallId;
                apiCall.has_some_problems__c = apiCallIdToObj.get(apiCall.Id).Expected_Status_Code__c != responseStatusCode;

                System.debug('@@@MAGAR : '+ apiCall.Expected_Status_Code__c );

                if(callForAuthorization)  {
                    External_System__c externalSystem = new External_System__c(Id = externalSystemId, Authorization_Key__c = responseBody);
                    uow.registerDirty(externalSystem);
                }

                uow.registerDirty(apiCall);
                performCommit = true;


            }
        }
        if(performCommit) {
            uow.commitWork();
        }

    }

    // public void callToExternalSystemForAuth() {
    //     fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { Api_Call__c.SObjectType, Api_Request__c.SObjectType, External_System__c.SObjectType });

    //     Map<Id, HttpRequest> externalSystemToApiRequest = new Map<Id, HttpRequest>();
    //     Map<Id, Id> apiCallToExternalSystem = new Map<Id, Id>();

    //     Map<Id, SObject> apiRequestsMap = new Map<Id, SObject>(Records);
    //     Map<Id, Api_Call__c> requestIdToApiCall = ApiCalls.getApiCallsWithApiRequestIdMap(apiRequestsMap.keySet());


    //     for(Api_Request__c apiRequest : (List<Api_Request__c>) Records) {
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint(apiRequest.Endpoint__c);
    //         req.setMethod(apiRequest.Type__c);
    //         externalSystemToApiRequest.put(apiRequest.External_System__c, req);
    //         apiCallToExternalSystem.put(apiRequest.External_System__c, requestIdToApiCall.get(apiRequest.Id).Id);
    //     }

    //     for(Id externalSystemId : externalSystemToApiRequest.keySet()) {
    //         HttpRequest httpReq = externalSystemToApiRequest.get(externalSystemId);
    //         Http http = new Http();
    //         HTTPResponse res = http.send(httpReq);
    //         String responseBody = res.getBody();
    //         String responseStatus = res.getStatus();
    //         String responseStatusCode = String.valueOf(res.getStatusCode());
            
    //         Api_Call__c apiCall = new Api_Call__c();
    //         apiCall.Response_status__c = responseStatus;
    //         apiCall.Response_status_code__c = responseStatusCode;
    //         apiCall.Response_message__c = responseBody;
    //         apiCall.Id = apiCallToExternalSystem.get(externalSystemId);
            
    //         External_System__c externalSystem = new External_System__c(Id = externalSystemId, Authorization_Key__c = responseBody);
    //         uow.registerDirty(externalSystem);
    //         uow.registerDirty(apiCall);
    //     }

    //     uow.commitWork();
    // }
}