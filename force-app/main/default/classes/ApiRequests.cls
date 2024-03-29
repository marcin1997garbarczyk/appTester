public with sharing class ApiRequests extends fflib_SObjectDomain {

    public ApiRequests(List<Api_Request__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ApiRequests(sObjectList);
        }
    }

    public void makeCalloutBasedOnApiRequest(Boolean callForAuthorization) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new Schema.SObjectType[] { Api_Call__c.SObjectType, Api_Request__c.SObjectType, External_System__c.SObjectType, Error_Log__c.SObjectType });

        Map<Id, Map<Id, HttpRequest>> externalSystemToApiRequest = new Map<Id, Map<Id, HttpRequest>>();
        Map<Id, Api_Call__c> apiCallIdToObj = new Map<Id, Api_Call__c>();
        Map<Id, SObject> apiRequestsMap = new Map<Id, SObject>(Records);
        Map<Id, List<Api_Call__c>> requestIdToApiCall = ApiCalls.generateApiRequestToListOfApiCallsMap(apiRequestsMap.keySet());
        Boolean performCommit = false;

        for(Api_Request__c apiRequest : (List<Api_Request__c>) Records) {
            for(Api_Call__c apiCall: requestIdToApiCall.get(apiRequest.Id)) {
                HttpRequest req = new HttpRequest();
                String endpoint = apiRequest.Endpoint__c;
                req.setMethod(apiRequest.Type__c);
                
                if(apiRequest.Input_params__c == 'In JSON') {
                    req.setBody(apiCall.Request_Body__c);
                    req.setHeader('Content-type', 'application/json; charset=UTF-8');
                }
                if(apiRequest.Input_params__c == 'In Url') {
                    endpoint += apiCall.Url_Param__c != null ? apiCall.Url_Param__c : '';
                }

                req.setEndpoint(endpoint);

                if(externalSystemToApiRequest.get(apiRequest.External_System__c) == null) externalSystemToApiRequest.put(apiRequest.External_System__c, new Map<Id, HttpRequest>());
                externalSystemToApiRequest.get(apiRequest.External_System__c).put(apiCall.Id, req);
                apiCallIdToObj.put(apiCall.Id, apiCall);
            }
        }
        Map<Id, Boolean> apiRequestHasSomeProblems = new Map<Id, Boolean>();
        Map<Id, Boolean> externalSystemHasSomeProblems = new Map<Id, Boolean>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        Map<Id, External_System__c> idToExternalSystemMap = new Map<Id, External_System__c>([SELECT Id , Start_date__c, Account__r.Id FROM External_System__c WHERE Id IN: externalSystemToApiRequest.keySet()]);
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
                Boolean apiHasSomeProblems = apiCallIdToObj.get(apiCall.Id).Expected_Status_Code__c != responseStatusCode;
                apiCall.has_some_problems__c = apiHasSomeProblems;
                
                Id apiReuqestId = apiCallIdToObj.get(apiCall.Id).Api_Request__r.Id;
                
                Api_Request__c apiRequest = new Api_Request__c(Id= apiReuqestId, has_some_problems__c = apiHasSomeProblems);
                External_System__c externalSystem = idToExternalSystemMap.get(externalSystemId);
                
                if(apiHasSomeProblems) {
                    uow.registerNew(new Error_Log__c(Name= 'Problem with: '+apiCallIdToObj.get(apiCall.Id).Name, Account__c = idToExternalSystemMap.get(externalSystemId).Account__r.Id,
                                                         External_system__c = externalSystemId, api_call__c = apiCallId
                                                        ,status__c = responseStatus, status_code__c = responseStatusCode, 
                                                        message__c = responseBody, expected_status_code__c = apiCallIdToObj.get(apiCall.Id).Expected_Status_Code__c));
                    uow.registerDirty(apiRequest);
                    apiRequestHasSomeProblems.put(apiReuqestId, true);
                } else if((apiRequestHasSomeProblems.get(apiReuqestId) != null && !apiRequestHasSomeProblems.get(apiReuqestId) && !apiHasSomeProblems) || apiRequestHasSomeProblems.get(apiReuqestId) == null) {
                    uow.registerDirty(apiRequest);
                }
                if(externalSystem.start_date__c == null) externalSystem.start_date__c = DateTime.now();
                externalSystem.Last_Date__c = DateTime.now();
                if(apiHasSomeProblems) {
                    externalSystem.has_some_problems__c = apiHasSomeProblems;
                    externalSystemHasSomeProblems.put(externalSystemId, true);
                } else if((externalSystemHasSomeProblems.get(externalSystemId) != null && !externalSystemHasSomeProblems.get(externalSystemId) && !apiHasSomeProblems ) || externalSystemHasSomeProblems.get(externalSystemId) == null) {
                    externalSystem.has_some_problems__c = apiHasSomeProblems;
                }

                uow.registerDirty(externalSystem);
                if(callForAuthorization)  {
                    externalSystem.Authorization_Key__c = responseBody;
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
}