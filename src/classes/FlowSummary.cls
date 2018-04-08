public with sharing class FlowSummary {
        @AuraEnabled Public String recId {get;set;}
        @AuraEnabled Public String Name {get;set;}
        @AuraEnabled Public String Description {get;set;}
        @AuraEnabled Public String Status {get;set;}
        @AuraEnabled Public String LastModifiedDate {get;set;}
        @AuraEnabled Public String LastModifiedByName {get;set;}
        @AuraEnabled Public String CreatedDate {get;set;}
        @AuraEnabled Public String CreatedByName {get;set;}
        @AuraEnabled Public String ObjectName {get;set;}
        @AuraEnabled Public String FullName {get;set;}
        @AuraEnabled Public String Version {get;set;}
        //reggie, I doubt the next one will work :(
        @AuraEnabled Public List<FlowSummary> OlderVersions {get;set;}
        public FlowSummary(){
            
        }
}