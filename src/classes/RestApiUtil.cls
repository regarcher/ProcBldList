public with sharing class RestApiUtil {
//Reg Archer March 16 2018....  

// /services/data/v41.0/tooling/query?q=SELECT+id,+lastmodifieddate,+lastModifiedByName+FROM+flow
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   public static List<FlowClass> getLatestFlowsDetailed(Integer pLimit){
       List<FlowClass> lstRetVal;
        //reggie, I'm going to let the caller catch and handle... 
       //try{
            List<Object> recordList = getBaseObjectList(pLimit);
            lstRetVal = getFlowClassList(recordList, pLimit);
           
       //}catch(Exception ex){
           //reggie, I need to get this error back to the Component....
       //    System.debug(LoggingLevel.warn, 'reggie ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
       //}
        return lstRetVal;
   }
  
      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static List<FlowClass> getFlowClassList(List<Object> pLstObjects, Integer pLimit){
        List<FlowClass> lstRetVal = new List<FlowClass>();

        Integer iLimit = pLimit;
        if (pLstObjects.size()<pLimit){
            iLimit = pLstObjects.size();
        }
        //NOTE, that I can't retrieve the Metadata in a massive call, it's got to happen one at a time
        for(Integer i=0;i<iLimit;i++) {
            //reggie, I may be able to do this a much more simple way
            Object myObj = pLstObjects[i];
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

            lstRetVal.addAll((List<FlowClass>) json.deserialize(strFlowTrimmed, List<FlowClass>.class));
            
        }
        return lstRetVal;

   }
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static List<Object> getBaseObjectList(Integer pLimit){
       List<Object> lstRetVal;

        //reggie, I suspect I will be inendated with versions....and I only want the latest version, so, be smart...maybe I 
        //reggie, try to cut out the older versions here and get only the latest?
        //reggie, here's a question, is it possible to have a recent version that is in draft and also have an active version?
        
        //reggie, I'm experiencing failures when I add more than just the ID to my query


        String strAllFlowIds = getJsonGetResponse('/services/data/v41.0/tooling/query?q=SELECT+id+FROM+flow+where+ProcessType+=+\'Workflow\'+order+by+VersionNumber+asc');
        //NOTE! that it really doesn't cost me much to retrieve ALL of the flow IDs, I can limit the number later
        //great, now see if we can de-serialize this into flows

        System.debug(LoggingLevel.warn, 'reggie strAllFlowIds: '+strAllFlowIds);
        Map<String, Object> mapFlow = (Map<String, Object>)JSON.deserializeUntyped(strAllFlowIds);

        lstRetVal = (List<Object>)mapFlow.get('records');

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

}