public with sharing class RestApiUtil {
//Reg Archer March 16 2018....  
    //This class is only concerned with bringing back Process Builder Flows (defined by ProcessType = Workflow)
    //What's the difference between a Base and a Detailed search you ask... 
    
    //Base search is capable of bringing back a list of flows, but is somewhat limited in that it can't bring back Metadata or FullName
    
    //Detailed search will bring back FullName and Metadata as mentioned above, but may only bring back one record at a time.
    //Note that Salesforce states that "A single Apex transaction can make a maximum of 100 callouts to an HTTP request or an API call."
    //Here's the question, would we expect that some Salesforce customers are going to have more than 100 different Process Builder processes (not versions)?....I think....Yes
    //Well, that's a sobering thought.  Sounds like we might need some sort of pagination.  :(

    //FullName notes: In my opinion, you're not missing much with FullName as MasterLabel is available in the base search. 
    //Here's an example of the difference for version 2 of my Process builder named "Account Update":
    //FullName: Account_Update-2 MasterLabel: Account Update

    //Metadata notes: capable of bringing back all of the details surrounding a Process Builder such as actions and decisions. 
    //While this class is capable of much in the area of Metadata, my initial interest is in the ObjectType which I believe will be useful for the end user
    
    Private static map<ID,FlowClass> mapIdToFlowClass;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
    public static List<FlowClass> getBaseFlows(Integer pLimit){
        return getBaseFlowClassList(pLimit).values();
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static List<FlowClass> getLatestFlowsDetailed(Integer pLimit){
        List<FlowClass> lstRetVal; 
        return getLatestDetailedFlowClassList(pLimit);
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<FlowClass> getLatestDetailedFlowClassList(Integer pLimit){
        //I only care about the most recent version and getLatestVersionIds takes care of this
        //reggie, I want to design this where all the inactive versions are Base records under the most recent one, this will need to change some in that case
        //reggie, as I don't want to lose the children
        //reggie, I also want to update mapIdToFlowClass
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
            i++;
            if (i>iLimit){
                break;
            }

            String strQueryWithMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+fullName,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+Metadata,+lastmodifieddate,+lastModifiedById+FROM+flow+WHERE+id+=+\''+myId+'\'';
            String strThisDetailedFlow = getJsonGetResponse(strQueryWithMetadata);
            //example of strThisFlow:
            //{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"Flow","records":[{"attributes":{"type":"Flow","url":"/services/data/v41.0/tooling/sobjects/Flow/30146000000YUh3AAG"},
            //"Description":"update some dumb field","FullName":"New_Contact-1","ManageableState":"unmanaged","MasterLabel":"New Contact","ProcessType":"Workflow","Status":"Active","VersionNumber":1}]}
            //NOTE, that metadata will be contained within this next trimmed string!
            String strFlowTrimmed = strThisDetailedFlow.substring(strThisDetailedFlow.indexof('['),strThisDetailedFlow.length()-1);
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
        //Note that all versions and status are included here
        //I'm sorting by Version to make life easier on me. I'm expecting the display component to do it's own sorting on LastModifiedDate
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
                mapIdToFlowClass.put(myFC.ID, myFC);
            }
        }
       return mapIdToFlowClass;
   }
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static string getJsonGetResponse(String pApiCall){
       //an example of pApiCall might be: /services/data/v41.0/tooling/query?q=SELECT+id+FROM+flow+WHERE+status+='Active'
       //and yes, I'm passing soql, but it is a private method, so I'm not too concerned
       Http httpCall = new Http();
       HttpRequest restRequest = new HttpRequest();
       HttpResponse res;
       restRequest.setTimeout(120000);

       String sessionId = getSessionId();
       String strUrl = URL.getSalesforceBaseUrl().toExternalForm()+pApiCall;

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
       return UserInfo.getSessionId();
   }
   /////////////////////////////////////// USEFUL REFERENCES ////////////////////////////////////////////////////////////////
    //Metadata API Developer Guide - FLOW record definition including sub classes
    // https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
    //Force.com Tooling API - FLOW record definition
    //https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flow.htm
    //Notes on complex JSON deserialization
    //https://developer.salesforce.com/forums/?id=906F0000000D8MPIA0

}