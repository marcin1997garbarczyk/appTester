public with sharing class ExternalSystems extends fflib_SObjectDomain {

    public ExternalSystems(List<External_System__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ExternalSystems(sObjectList);
        }
    }

    public void downloadAuthorizationKey() {
        Set<Id> externalSystemToAuthorizeIds = new Set<Id>();

        for(External_System__c es : (List<External_System__c>) Records) {
            if(es.Authorization_Type__c != 'In request url') {
                externalSystemToAuthorizeIds.add(es.Id);
            }
        }


        ApiRequests apiRequests = new ApiRequests([SELECT Id, Endpoint__c, Type__c, External_System__c
                                                    FROM 
                                                        Api_Request__c 
                                                    WHERE 
                                                        External_System__c IN: externalSystemToAuthorizeIds
                                                        AND RecordType.DeveloperName = 'Authorization_request'
                                                       ]);
        apiRequests.callToExternalSystem(true);
    }

    public void testExternalApi() {
        Map<Id, SObject> externalSystemsMap = new Map<Id, SObject>(Records);
        downloadAuthorizationKey();

        ApiRequests apiRequests = new ApiRequests([SELECT Id, Endpoint__c, Type__c, External_System__c, Input_params__c
                                                    FROM 
                                                        Api_Request__c 
                                                    WHERE 
                                                        External_System__c IN: externalSystemsMap.keySet()
                                                        AND RecordType.DeveloperName != 'Authorization_request'
                                                       ]);

        apiRequests.callToExternalSystem(false);
    }
}