public with sharing class RestApiUtil {
//Reg Archer March 16 2018....  

// /services/data/v41.0/tooling/query?q=SELECT+id,+lastmodifieddate,+lastModifiedByName+FROM+flow
    Private static map<ID,FlowClass> mapIdToFlowClass;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
    public static List<FlowClass> getBaseFlows(Integer pLimit){
        //note that the base query will not bring back FullName or Metadata (used to derive ObjectType)
        //Note that all versions are included here, the caller should parse the children appropriately
        return getBaseFlowClassList(pLimit).values();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static List<FlowClass> getLatestFlowsDetailed(Integer pLimit){
        List<FlowClass> lstRetVal;
        //I'm going to let the caller catch and handle... 
        return getLatestDetailedFlowClassList(pLimit);
    }
  
      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<FlowClass> getLatestDetailedFlowClassList(Integer pLimit){
        //I only care about the most recent version and getLatestVersionIds takes care of this
        List<FlowClass> lstRetVal = new List<FlowClass>();
        getBaseFlowClassList(pLimit);
        List<String> listLatestIds = getLatestVersionIds(pLimit);

        Integer iLimit = pLimit;
        if (listLatestIds.size()<pLimit){
            iLimit = listLatestIds.size();
        }
        //NOTE, that I can't retrieve the Metadata in a massive call, it's got to happen one at a time
        integer i = 0;
        for(string myId:listLatestIds) {
            System.debug(LoggingLevel.warn, 'myId: '+myId);
            i++;
            if (i>iLimit){
                break;
            }
            // https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
            //ooooo, this next one is much better!
            //https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flow.htm

            String strQueryWithMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+fullName,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+Metadata,+lastmodifieddate,+lastModifiedById+FROM+flow+WHERE+id+=+\''+myId+'\'';
            String strThisDetailedFlow = getJsonGetResponse(strQueryWithMetadata);
            //example of strThisFlow:
            //{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"Flow","records":[{"attributes":{"type":"Flow","url":"/services/data/v41.0/tooling/sobjects/Flow/30146000000YUh3AAG"},
            //"Description":"update some dumb field","FullName":"New_Contact-1","ManageableState":"unmanaged","MasterLabel":"New Contact","ProcessType":"Workflow","Status":"Active","VersionNumber":1}]}
            //NOTE, that metadata will be contained within this next trimmed string!
            String strFlowTrimmed = strThisDetailedFlow.substring(strThisDetailedFlow.indexof('['),strThisDetailedFlow.length()-1);
            //some references
            //I think this is taking me in the right direction... 
            //https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
            //OK, maybe this one is better.....
            //https://developer.salesforce.com/forums/?id=906F0000000D8MPIA0

            lstRetVal.addAll((List<FlowClass>) json.deserialize(strFlowTrimmed, List<FlowClass>.class));
            
        }
        return lstRetVal;

   }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<string> getLatestVersionIds(integer pLimit){
        //note that the soql statement sorts by version asc, so we're trusting that these will be in order
        map<String, String> mapFlowNameToId = new map<String, String>();
        for (FlowClass myFC:getBaseFlowClassList(pLimit).values()){
            mapFlowNameToId.put(myFC.MasterLabel, myFC.Id);
        }
        return mapFlowNameToId.values();
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static map<ID,FlowClass> getBaseFlowClassList(Integer pLimit){
        //this method will only get called when map<id,FlowClass> is null!
        //Note that it will get all Workflow(Process builder) flows
        //and will populate them into the map<id,FlowClass>
        //note that the base query will not bring back FullName or Metadata (used to derive ObjectType)
        //Note that all versions are included here
        if (mapIdToFlowClass==null || mapIdToFlowClass.size()==0){
            //reggie, I need to include the LIMIT in this query!!!!
            String strBaseQueryMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+lastmodifieddate,+lastModifiedById+FROM+flow+where+ProcessType+=+\'Workflow\'++order+by+VersionNumber+asc';
            String strAllFlows = getJsonGetResponse(strBaseQueryMetadata);
            String strAllFlowsTrimmed = strAllFlows.substring(strAllFlows.indexof('['),strAllFlows.length()-1);
            List<FlowClass> lstLocalFlowClasses = (List<FlowClass>) json.deserialize(strAllFlowsTrimmed, List<FlowClass>.class);
            if (mapIdToFlowClass==null){
                mapIdToFlowClass = new map<ID,FlowClass>();
            }
            for (FlowClass myFC:lstLocalFlowClasses){
                System.debug(LoggingLevel.warn, 'reggie myFC: '+myFC);
                mapIdToFlowClass.put(myFC.ID, myFC);
            }
        }
       return mapIdToFlowClass;

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