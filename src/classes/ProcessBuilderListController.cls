public with sharing class ProcessBuilderListController {
    Private static map<ID,User> mapIdToUser;
    @AuraEnabled
    public static String getLatestBaseFlowSummaryList(Integer pLimit){
        //REGGIE, I REALLY WANT TO RETURN PARENTS AND CHILDREN IN THIS ONE....IT DOESN'T COST ME ANYTHING MORE
        //This method will get the most recent versions of Process Builders, regardless of status. 
        //It only brings back fields that are available on the base query
        //This would NOT include FullName  or ObjectType
        //Of course name is still available, so objectType (objectName) is really the only deficiency
        //NOTE however as this package matures, we may pull a lot more off the Metadata response

        //The return value will be a JSON serialized string of List<FlowSummary>
        String lRetVal;
        try{

            List<FlowClass> lstAllBaseFlows = RestApiUtil.getBaseFlows(pLimit);
            List<FlowSummary> lstFlowSummary = getFlowSummaryList(lstAllBaseFlows);
            lRetVal = JSON.serialize(lstFlowSummary);
        }catch(Exception ex){
            System.debug(LoggingLevel.warn, 'reggie ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
            Throw new AuraHandledException('An error was encountered' + ex + ' STACKTRACE: '+ex.getStackTraceString());
        }
        //reggie, great, but, now I need to just return the latest!.....maybe...maybe I return with the children?????

        return lRetVal;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String getLatestDetailedFlowSummaryList(Integer pLimit){
        //this method will get ALL fields for all most recent versions of Process Builders regardless of status
        //This would NOT include FullName (FullName) or ObjectType (ObjectName)
        //This begs the question, what field CAN I use to substitute in for MasterLabel?
  
        //The return value will be a JSON serialized string of List<FlowSummary>
        String lRetVal;
        Try{
            List<FlowClass> lstFlowClass = RestApiUtil.getLatestFlowsDetailed(pLimit);
            List<FlowSummary> lstFlowSummary = getFlowSummaryList(lstFlowClass);
            lRetVal = JSON.serialize(lstFlowSummary);
        }catch(Exception ex){
            System.debug(LoggingLevel.warn, 'reggie ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
            Throw new AuraHandledException('An error was encountered' + ex + ' STACKTRACE: '+ex.getStackTraceString());
        }
        return lRetVal;

    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<FlowSummary> getFlowSummaryList(List<FlowClass> pLstFlowClass){
        //reggie NOTE that at this moment this is not getting the latest version, its getting everything!
        List<FlowSummary> lstRetVal = new List<FlowSummary>();
        Set<String> setUserIds = new Set<String>();
        for (FlowClass myFC:pLstFlowClass){
            setUserIds.add(myFC.LastModifiedById); 
        }
        getUsers(setUserIds);
        for (FlowClass myFC:pLstFlowClass){
            lstRetVal.add(buildFlowSummary(myFC));
        }
        return lstRetVal;
   }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    private static FlowSummary buildFlowSummary(FlowClass pFlowClass){

        FlowSummary myFS = new FlowSummary();
        if (pFlowClass.OlderVersions!=null && pFlowClass.OlderVersions.size()>0){
            myFS.OlderVersions = new List<FlowSummary>();
            for (FlowClass thisOlderVersion:pFlowClass.OlderVersions){
                myFS.OlderVersions.add(buildFlowSummary(thisOlderVersion));
            }
        }
        myFS.recId = pFlowClass.Id;
        myFS.Name = pFlowClass.MasterLabel;
        myFS.Description = pFlowClass.Description;
        myFS.Status = pFlowClass.Status;
        myFS.LastModifiedDate = pFlowClass.Lastmodifieddate.left(19);
        myFS.LastModifiedByName = mapIdToUser.get(pFlowClass.LastModifiedById).name;
        myFS.Version = pFlowClass.VersionNumber;

        if (pFlowClass.MetaData!=null && pFlowClass.MetaData.processMetadataValues!=null){
            for (FlowClass.FlowMetadataValue myFMV:pFlowClass.MetaData.processMetadataValues){
                if (myFMV.name=='ObjectType'){
                    myFS.ObjectName = myFMV.value.stringValue;
                    //break;
                }
            }
        }else{
            //reggie, can I get the name from anywhere else?
        }
        
        //myFS.ObjectName = myFC.MetaData.processMetadataValues[0].stringValue;
        myFS.FullName = pFlowClass.FullName;
        System.debug('myFS: '+myFs);
        return myFS;

    }
  
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static map<ID,User> getUsers(Set<String> pSetUserIds){
       //these users might or might not already be here, so, let's make sure they're available to our caller
        Set<String> setUsersToRetrieve = new Set<String>();
        if (pSetUserIds!=null && pSetUserIds.size()>0){
            if (mapIdToUser==null){
                mapIdToUser = new map<ID,User>();
            }
            for (ID myID:pSetUserIds){
                if (mapIdToUser.get(myId)==null){
                    setUsersToRetrieve.add(myId);
                }
            }
            if (setUsersToRetrieve.size()>0){
                mapIdToUser.putAll([select id, name from user where id in :setUsersToRetrieve]);
            }
        }
        return mapIdToUser;
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
        Public String Version;
        Public List<FlowSummary> OlderVersions;
        public FlowSummary(){
            
        }
            
    }


}