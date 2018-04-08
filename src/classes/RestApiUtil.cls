public with sharing class RestApiUtil {
//Reg Archer March 16 2018....  
    //This class is only concerned with bringing back Process Builder Flows (defined by ProcessType = Workflow)
    //What's the difference between a Base and a Detailed search you ask... 
    
    //Base search is capable of bringing back a list of flows, but is somewhat limited in that it can't bring back Metadata or FullName
    
    //Detailed search will bring back FullName and Metadata as mentioned above, but may only bring back one record at a time.
    //Note that Salesforce states that "A single Apex transaction can make a maximum of 100 callouts to an HTTP request or an API call."
    //Here's the question, would we expect that some Salesforce customers are going to have more than 100 different Process Builder processes (not versions)?....I think....Yes
    //Well, that's a sobering thought.  Sounds like we might need some sort of pagination or filtering.  :(
    //One advantage of this design though is that even if you run into the limit, you'll still have the base values in the final list

    //FullName notes: In my opinion, you're not missing much with FullName as MasterLabel is available in the base search. 
    //Here's an example of the difference for version 2 of my Process builder named "Account Update":
    //FullName: "Account_Update-2" MasterLabel: "Account Update"

    //Metadata notes: capable of bringing back all of the details surrounding a Process Builder such as actions and decisions. 
    //While this class is capable of much in the area of Metadata, my initial interest is in the ObjectType which I believe will be useful for the end user
    
    //reggie, here's an example of pagination: http://sfdcmonkey.com/2017/01/26/display-record-with-pager-buttons-lightning-component/
    //reggie, that's probably going to be helpful, but, what happens if they start searching or sorting?????

    Private static map<ID,FlowClass> mapIdToFlowClass;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
    public static List<FlowClass> getBaseFlows(){
        List<FlowClass> lstRetVal; 
        String sessionId = getSessionId();
        //return getBaseFlowClassList().values();
        getBaseFlowClassList();
        return lstRetVal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public static List<FlowClass> getLatestFlowsDetailed(){
        List<FlowClass> lstRetVal; 
        String sessionId = getSessionId();
        //return getDetailedFlowClassList();
         getDetailedFlowClassList();
        return lstRetVal;
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
            System.debug(LoggingLevel.warn, 'strAllFlowsTrimmed: '+strAllFlowsTrimmed);
            List<FlowClass> lstLocalFlowClasses = (List<FlowClass>) json.deserialize(strAllFlowsTrimmed, List<FlowClass>.class);
            buildParentChildStructure(lstLocalFlowClasses);
        }
       return mapIdToFlowClass;
   }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private static List<FlowClass> getDetailedFlowClassList(){
        //reggie, I need to come up with a plan for using pLimit
        //as we know, I can only make 99 of these...any SF customer with more than that will have issues with the way it is today
        List<FlowClass> lstRetVal = new List<FlowClass>();
        //getBaseFlowClassList() will return mapIdToFlowClass and we know that all the Keys on that are just the most recent versions
        List<String> listLatestIdsWithoutDetail = getLatestVersionNotHavingDetail(getBaseFlowClassList().values());

        //NOTE, that I can't retrieve the Metadata in a massive call, it's got to happen one at a time

        for(string myId:listLatestIdsWithoutDetail) {
            if (Limits.getLimitCallouts()==0){
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
        debugPrintResults(lstRetVal);
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
       //reggie, this was the old call before we went to Named Credentials
       //String strUrl = URL.getSalesforceBaseUrl().toExternalForm()+pApiCall;
        //reggie, here's the setEndPoint...today our strUrl is the external base url + the api call... /services/data.... 
        //reggie, but tomorrow, we want to use named credentials... for example setEndpoint('callout:***My_Named_Credential***/some_path');
        //reggie, NOPE, this Named Creditial did not fix my problem :( It still works for Execute anonymous, but it still fails for the Lightning App
        String strUrl = 'callout:Tooling_Api'+pApiCall;
       restRequest.setEndpoint(strUrl);
       restRequest.setMethod('GET');
       restRequest.setHeader('Content-Type', 'application/json');
       //reggie, both Bearer and OAuth work for execute anonymous but fail for lighting app based call
       restRequest.setHeader('Authorization', 'Bearer '+ sessionId);
       //restRequest.setHeader('Authorization', 'OAuth '+ pSessionId);
       HttpResponse callResponse;
       String responseBody;
        callResponse = httpCall.send(restRequest);
        responseBody = callResponse.getBody();
       return responseBody;
   }
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static String getSessionId() {
       //NOTE that sessionId can not be printed out on the Debug
       System.debug('reggie orgID: '+ UserInfo.getOrganizationId().substring(0, 15) + ' reggie sessionID:' +  UserInfo.getSessionId().substring(15));
       System.debug('reggie userName: '+UserInfo.getName());
       return UserInfo.getSessionId();
   }
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static void debugPrintResults(List<FlowClass> pLstFlowClass){
        for (FlowClass myFC:pLstFlowClass){
            System.debug(LoggingLevel.warn, 'MasterLabel: '+myFC.MasterLabel+' VersionNumber: '+myFC.VersionNumber);
            if (myFC.MetaData!=null && myFC.MetaData.processMetadataValues!=null){
                for (FlowClass.FlowMetadataValue myFMV:myFC.MetaData.processMetadataValues){
                    if (myFMV.name=='ObjectType'){
                        System.debug(LoggingLevel.warn, 'ObjectName: '+myFMV.value.stringValue);
                    }
                }
            }
            if (myFC.OlderVersions!=null){
                for (FlowClass myFCOV:myFC.OlderVersions){
                    System.debug(LoggingLevel.warn, '......OLDER VERSION NAME: '+myFCOV.MasterLabel+' OLDER VERSION: '+myFCOV.VersionNumber);
                    //System.debug(LoggingLevel.warn, 'OLDER VERSION '+myFSOV);
                }
            }

        }
    }
   /////////////////////////////////////// USEFUL REFERENCES ////////////////////////////////////////////////////////////////
    //Metadata API Developer Guide - FLOW record definition including sub classes
    // https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
    //Force.com Tooling API - FLOW record definition
    //https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flow.htm
    //Notes on complex JSON deserialization
    //https://developer.salesforce.com/forums/?id=906F0000000D8MPIA0

    //security and session notes... 
    //"By security policy, sessions created by Lightning components aren’t enabled for API access"
    //https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/apex_api_calls.htm
    //"Carefully review any code that uses a named credential to ensure you’re not creating a vulnerability."
    //"You can also skip remote site settings, which are otherwise required for callouts to external sites, for the site defined in the named credential."
    //"if an endpoint URL changes, you update only the named credential. All callouts that reference the named credential simply continue to work."
    //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_named_credentials.htm
    //https://help.salesforce.com/articleView?id=named_credentials_define.htm&type=5
    //this looked promising, but didn't seem to work either
    //https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/js_api_calls_platform.htm
    //So, this page says that you simply can't do it without cheating
    //https://salesforce.stackexchange.com/questions/110515/getting-session-id-in-lightning
    //and if you have locker service turned on, this hack will simply fail


}