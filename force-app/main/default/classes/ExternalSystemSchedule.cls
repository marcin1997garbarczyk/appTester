public without sharing class ExternalSystemSchedule implements Schedulable {
    public void execute(SchedulableContext ctx) {
        testExternalSystem();
    }

    @Future(callout=true)
    public static void testExternalSystem() {
        ExternalSystems externalSystems = new ExternalSystems([SELECT Id, Authorization_type__c, Authorization_Key__c FROM External_System__c WHERE Account__r.Active_checking__c = TRUE]);
        externalSystems.runTestOnApiRequestUnderExternalSystems();

    }

}