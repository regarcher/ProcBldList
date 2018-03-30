public with sharing class RestApiUtil {
//Reg Archer March 16 2018....  

// /services/data/v41.0/tooling/query?q=SELECT+id,+lastmodifieddate,+lastModifiedByName+FROM+flow
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   public static List<FlowSummary> getAllFlows(Integer pLimit){
       List<FlowSummary> lstRetVal = new List<FlowSummary>();
       List<FlowClass> lstMyFC = new List<FlowClass>();
       Set<String> lstUserIds = new Set<String>();
       Map<ID, User> mapIdToUser = new Map<ID,User>();
       try{
            //reggie, I can worry about active later..... 
           //String strAllActiveFlowIds = getJsonGetResponse('/services/data/v41.0/tooling/query?q=SELECT+id+FROM+flow+WHERE+status+=\'Active\'');
           //reggie, I suspect I will be inendated with versions....and I only want the latest version, so, be smart...maybe I 
           //reggie, try to cut out the older versions here and get only the latest?
           //reggie, here's a question, is it possible to have a recent version that is in draft and also have an active version?
           String strAllFlowIds = getJsonGetResponse('/services/data/v41.0/tooling/query?q=SELECT+id+FROM+flow');
           //NOTE! that it really doesn't cost me much to retrieve ALL of the flow IDs, I can limit the number later
           //great, now see if we can de-serialize this into flows
    

           Map<String, Object> mapFlow = (Map<String, Object>)JSON.deserializeUntyped(strAllFlowIds);
    
           List<Object> recordList = (List<Object>)mapFlow.get('records');
          
            Integer iLimit = pLimit;
            if (recordList.size()<iLimit){
                iLimit = recordList.size();
            }
            //NOTE, that I can't retrieve the Metadata in a massive call, it's got to happen one at a time
           for(Integer i=0;i<iLimit;i++) {
               //reggie, I may be able to do this a much more simple way
               Object myObj = recordList[i];
                Map<String,Object> mapStringObj =  (Map<String,Object>) myObj;
                String strTempId = String.valueOf(mapStringObj.get('Id'));
                
                // https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
                //ooooo, this next one is much better!
                //https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flow.htm
    
                String strQueryWithMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+fullName,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+Metadata,+lastmodifieddate,+lastModifiedById+FROM+flow+WHERE+id+=+\''+strTempId+'\'';
               
                String strThisFlow = getJsonGetResponse(strQueryWithMetadata);
               
                //example of strThisFlow:
                //{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"Flow","records":[{"attributes":{"type":"Flow","url":"/services/data/v41.0/tooling/sobjects/Flow/30146000000YUh3AAG"},
                //"Description":"update some dumb field","FullName":"New_Contact-1","ManageableState":"unmanaged","MasterLabel":"New Contact","ProcessType":"Workflow","Status":"Active","VersionNumber":1}]}
                //NOTE, that metadata will be contained within this next trimmed string!
                String strFlowTrimmed = strThisFlow.substring(strThisFlow.indexof('['),strThisFlow.length()-1);
                //reggie, I've done a bunch of googling on how to parse the metadata, but haven't found it
                //reggie, so, my options are these 1. keep googling 2. do a bunch of trial and error till I get it?
                //I think this is taking me in the right direction... 
                //https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
                //OK, maybe this one is better.....
                //https://developer.salesforce.com/forums/?id=906F0000000D8MPIA0
    			System.debug(LoggingLevel.warn, 'reggie strFlowTrimmed: '+strFlowTrimmed);
    
                lstMyFC.addAll((List<FlowClass>) json.deserialize(strFlowTrimmed, List<FlowClass>.class));
               
           }

           for (FlowClass myFC:lstMyFC){
               System.debug(LoggingLevel.warn, 'reggie myFC: '+myFC);
               lstUserIds.add(myFC.LastModifiedById); 
           }

           mapIdToUser.putAll([select id, name from user where id in :lstUserIds]);

           //
           for (FlowClass myFC:lstMyFC){
               //reggie, I don't understand why there's a list of processMetadataValues, when that's where I need to get my Object type from????
               FlowSummary myFS = new FlowSummary();
               myFS.recId = myFC.Id;
               myFS.Name = myFC.MasterLabel;
               myFS.Description = myFC.Description;
               myFS.Status = myFC.Status;
               myFS.LastModifiedDate = myFC.Lastmodifieddate.left(19);
               myFS.LastModifiedByName = mapIdToUser.get(myFC.LastModifiedById).name;
               System.debug('reggie myFC.MetaData.processMetadataValues.size(): '+myFC.MetaData.processMetadataValues.size());
               for (FlowClass.FlowMetadataValue myFMV:myFC.MetaData.processMetadataValues){
                   System.debug('reggie myFMV: '+myFMV);
                   if (myFMV.name=='ObjectType'){
                       myFS.ObjectName = myFMV.value.stringValue;
                       //break;
                   }
               }
               //myFS.ObjectName = myFC.MetaData.processMetadataValues[0].stringValue;
               myFS.FullName = myFC.FullName;
               lstRetVal.add(myFS);
 
               System.debug(LoggingLevel.warn, 'reggie myFS: '+myFS);
           }
       }catch(Exception ex){
           //reggie, I need to get this error back to the Component....
           System.debug(LoggingLevel.warn, 'reggie ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
       }
       return lstRetVal;
   }
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static string getJsonGetResponse(String pApiCall){
       //an example of pApiCall might be: /services/data/v41.0/tooling/query?q=SELECT+id+FROM+flow+WHERE+status+='Active'
       Http httpCall = new Http();
       HttpRequest restRequest = new HttpRequest();
       HttpResponse res;
       restRequest.setTimeout(120000);

       String sessionId = getSessionId();
       String strUrl = URL.getSalesforceBaseUrl().toExternalForm()+pApiCall;
       //System.debug(LoggingLevel.warn, 'reggie strUrl: '+strUrl);

       restRequest.setEndpoint(strUrl);
       restRequest.setMethod('GET');
       restRequest.setHeader('Content-Type', 'application/json');
       restRequest.setHeader('Authorization', 'Bearer '+ sessionId);
       HttpResponse callResponse;
       String responseBody;
       if(!Test.isRunningTest()){
           callResponse = httpCall.send(restRequest);
           responseBody = callResponse.getBody();
       }
       return responseBody;
   }

   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static String getSessionId() {
       //NOTE that sessionId can not be printed out on the Debug
       //
       return UserInfo.getSessionId();
   }
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Public class FlowSummary{
        Public String recId;
        Public String Name;
        Public String Description;
        Public String Status;
        Public String LastModifiedDate;
        Public String LastModifiedByName;
        Public String ObjectName;
        Public String FullName;
        public FlowSummary(){
            
        }
            
    }
	


}