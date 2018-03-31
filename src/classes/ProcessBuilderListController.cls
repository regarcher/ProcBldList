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
        //note that only BASE calls will have children.....the detailed calls only get the latest version (currenly anywa)
        map<String, List<FlowClass>> myVersionMap =  getVersionMap(pLstFlowClass);
        //reggie, great, now I've got a map that tells me who is in the non-last position and in the last postion
        //reggie, it seems to me that now I really need to process the LAST entry in the map in the next for list
        //reggie, inside the for loop I can go pull the children and attach them 
        //reggie, this means that FlowSummary needs to change slightly to have children (older versions)
        //reggie, it gets hairy here, and thus it's probably not a Badger release?

        for (FlowClass myFC:pLstFlowClass){
            //reggie, I don't understand why there's a list of processMetadataValues, when that's where I need to get my Object type from????
            FlowSummary myFS = new FlowSummary();
            myFS.recId = myFC.Id;
            myFS.Name = myFC.MasterLabel;
            myFS.Description = myFC.Description;
            myFS.Status = myFC.Status;
            myFS.LastModifiedDate = myFC.Lastmodifieddate.left(19);
            myFS.LastModifiedByName = mapIdToUser.get(myFC.LastModifiedById).name;
            myFS.Version = myFC.VersionNumber;

            if (myFC.MetaData!=null && myFC.MetaData.processMetadataValues!=null){
                for (FlowClass.FlowMetadataValue myFMV:myFC.MetaData.processMetadataValues){
                    if (myFMV.name=='ObjectType'){
                        myFS.ObjectName = myFMV.value.stringValue;
                        //break;
                    }
                }
            }else{
                //reggie, can I get the name from anywhere else?
            }
            
            //myFS.ObjectName = myFC.MetaData.processMetadataValues[0].stringValue;
            myFS.FullName = myFC.FullName;
            lstRetVal.add(myFS);

            System.debug(LoggingLevel.warn, 'reggie myFS: '+myFS);
        }
        return lstRetVal;

   }
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   private static map<String, List<FlowClass>> getVersionMap(List<FlowClass> pFlowClasses){
        //this will be called by the Base request method.....we're planning on providing everything
        //in an ascending order as we know that the RestApiUtil ordered by version ascending
        map<String, List<FlowClass>> mapMasterLabelToListFlowClass = new map<String, List<FlowClass>>();
        for (FlowClass myFC:pFlowClasses){
            if (mapMasterLabelToListFlowClass.get(myFC.MasterLabel)==null){
                mapMasterLabelToListFlowClass.put(myFC.MasterLabel, new List<FlowClass>());
            }
            mapMasterLabelToListFlowClass.get(myFC.MasterLabel).add(myFC);
        }
        return mapMasterLabelToListFlowClass;
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
        public FlowSummary(){
            
        }
            
    }


}