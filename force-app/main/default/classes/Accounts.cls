public with sharing class Accounts extends fflib_SObjectDomain {

    public Accounts(List<Account> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Accounts(sObjectList);
        }
    }

    public void testApiForAccount() {
        Map<Id, SObject> accountsMap = new Map<Id, SObject>(Records);
        ExternalSystems externalSystems = new ExternalSystems([SELECT Id, Authorization_type__c, Authorization_Key__c FROM External_System__c WHERE Account__r.Id IN: accountsMap.keySet()]);
        externalSystems.testExternalApi();
    }
}