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
    
    //reggie, here's an example of pagination: http://sfdcmonkey.com/2017/01/26/display-record-with-pager-buttons-lightning-component/
    //reggie, that's probably going to be helpful, but, what happens if they start searching or sorting?????

    Private static map<ID,FlowClass> mapIdToFlowClass;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
    public static List<FlowClass> getBaseFlows(){

        return getBaseFlowClassList().values();
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static List<FlowClass> getLatestFlowsDetailed(Integer pLimit){
        List<FlowClass> lstRetVal; 
        return getDetailedFlowClassList(pLimit);
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static map<ID,FlowClass> getBaseFlowClassList(){
        //Note that all versions and status are included here
        //I'm sorting by Version to make life easier on me. I'm expecting the display component to do it's own sorting on LastModifiedDate
        if (mapIdToFlowClass==null || mapIdToFlowClass.size()==0){
            String strBaseQueryMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+lastmodifieddate,+lastModifiedById,+createddate,+createdById+FROM+flow+where+ProcessType+=+\'Workflow\'++order+by+lastmodifieddate+desc';
            String strAllFlows;
            //we can't make callouts from test, so.... 
            if (Test.isRunningTest()){
                strAllFlows = TestDataFactory.getBaseRestResponse();
            }else{
                strAllFlows = getJsonGetResponse(strBaseQueryMetadata);
            }
            String strAllFlowsTrimmed = strAllFlows.substring(strAllFlows.indexof('['),strAllFlows.length()-1);
            List<FlowClass> lstLocalFlowClasses = (List<FlowClass>) json.deserialize(strAllFlowsTrimmed, List<FlowClass>.class);
            buildParentChildStructure(lstLocalFlowClasses);
        }
       return mapIdToFlowClass;
   }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<FlowClass> getDetailedFlowClassList(Integer pLimit){
        //reggie, I need to come up with a plan for using pLimit
        //as we know, I can only make 99 of these...any SF customer with more than that will have issues with the way it is today
        List<FlowClass> lstRetVal = new List<FlowClass>();
        //getBaseFlowClassList() will return mapIdToFlowClass and we know that all the Keys on that are just the most recent versions
        List<String> listLatestIdsWithoutDetail = getLatestVersionNotHavingDetail(getBaseFlowClassList().values());

        Integer iLimit = pLimit;
        if (listLatestIdsWithoutDetail.size()<pLimit){
            iLimit = listLatestIdsWithoutDetail.size();
        }
        //NOTE, that I can't retrieve the Metadata in a massive call, it's got to happen one at a time
        integer i = 0;
        for(string myId:listLatestIdsWithoutDetail) {
            i++;
            if (i>iLimit){
                break;
            }
            String strQueryWithMetadata = '/services/data/v41.0/tooling/query?q=SELECT+Id,+Description,+fullName,+ManageableState,+MasterLabel,+ProcessType,+Status,+VersionNumber,+Metadata,+lastmodifieddate,+lastModifiedById,+createddate,+createdById+FROM+flow+WHERE+id+=+\''+myId+'\'';
            String strThisDetailedFlow;
            //we can't make callouts from test, so.... 
            if (!Test.isRunningTest()){
                strThisDetailedFlow = getJsonGetResponse(strQueryWithMetadata);
            }
            //NOTE, that metadata will be contained within this next trimmed string!
            String strFlowTrimmed;
            if (Test.isRunningTest()){
                strFlowTrimmed = TestDataFactory.getDetailedTrimmedResponse2(); 
            }else{
                strFlowTrimmed = strThisDetailedFlow.substring(strThisDetailedFlow.indexof('['),strThisDetailedFlow.length()-1);
            }
            lstRetVal.addAll((List<FlowClass>) json.deserialize(strFlowTrimmed, List<FlowClass>.class));
        }
        //great, now we've got the list of detailed records for all the latest versions....note however, that we also have the children from the 
        //base call.  While in version 1 of this code we're interested in very little metadata fields, we might be interested in more later.
        //for this reason, I'm wanting to replace all the map base value for the latest version and simply copy their OlderVersions over to thise records... 
        for (FlowClass myFC:lstRetVal){
            FlowClass myMapFC = mapIdToFlowClass.get(myFC.Id);
            if (myMapFC!=null && myMapFC.OlderVersions!=null && myMapFC.OlderVersions.size()>0){
                myFC.OlderVersions = myMapFC.OlderVersions;
            }
            myFC.hasDetail = true;
            mapIdToFlowClass.put(myFC.id, myFC);
        } 
        return mapIdToFlowClass.values();
   }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<string> getLatestVersionIds(List<FlowClass> pLstFlowClass){
        //keep in mind that our Base soql query did an order by lastmodifieddate desc
        map<String, String> mapFlowNameToId = new map<String, String>();
        for (FlowClass myFC:pLstFlowClass){
            if ( mapFlowNameToId.get(myFC.MasterLabel)==null){
                mapFlowNameToId.put(myFC.MasterLabel, myFC.Id);
            }
        }
        return mapFlowNameToId.values();
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<string> getLatestVersionNotHavingDetail(List<FlowClass> pLstFlowClass){
        //note that the soql statement sorts by version asc, so we're trusting that these will be in order
        List<string> lstRetVal = new List<String>();
        for (FlowClass myFC:pLstFlowClass){
            if (myFC.hasDetail==false){
                lstRetVal.add(myFC.Id);
            }
        }
       return lstRetVal;
    }
    
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static map<ID,FlowClass> buildParentChildStructure(List<FlowClass> pLstFlowClass){
       //I'm expecting that this will only get called from the Base query method, Detail queries should only be augmenting the latest versions
        map<String,List<FlowClass>> mapMasterLabelToOlderVersions =  new map<String,List<FlowClass>>();
        if (mapIdToFlowClass==null){
                mapIdToFlowClass = new map<ID,FlowClass>();
        }
        for (FlowClass myFC: pLstFlowClass){
            mapMasterLabelToOlderVersions.put(myFC.MasterLabel, new List<FlowClass>());
        }
        List<string> lstLatestVersionIds = getLatestVersionIds(pLstFlowClass);
        for (FlowClass myFC: pLstFlowClass){
            if (!lstLatestVersionIds.contains(myFC.Id)){
                mapMasterLabelToOlderVersions.get(myFC.MasterLabel).add(myFC);
            }else{
                //this IS a latest version, so we'll put this one in the Map
                mapIdToFlowClass.put(myFC.Id, myFC);
            }
        }
        //great, now we have 2 maps, our master latest versions map and a map of the older versions
        //now let's go put the older versions on the FlowClass.OlderVersions variable
        for (FlowClass myFC:mapIdToFlowClass.Values()){
            myFC.hasDetail = false;
            if (mapMasterLabelToOlderVersions.get(myFC.MasterLabel)!=null && mapMasterLabelToOlderVersions.get(myFC.MasterLabel).size()>0){
                myFC.OlderVersions = mapMasterLabelToOlderVersions.get(myFC.MasterLabel);
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
        callResponse = httpCall.send(restRequest);
        responseBody = callResponse.getBody();
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