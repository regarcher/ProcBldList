public with sharing class ProcessBuilderListController {
    Private static map<ID,User> mapIdToUser;
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled 
    public static List<FlowSummary> getBaseFlowSummaryList(){
        //Only brings back fields that are available on the base query
        //This would NOT include FullName  or ObjectType
        //Of course name is still available, so objectType (objectName) is really the only deficiency
        //NOTE however as this package matures, we may pull a lot more off the Metadata response
        //The return value will be a JSON serialized string of List<FlowSummary>
        List<FlowSummary> lstRetVal;
        try{
            List<FlowClass> lstAllBaseFlows = RestApiUtil.getBaseFlows();
            lstRetVal = getFlowSummaryList(lstAllBaseFlows);
            debugPrintResults(lstRetVal);
            //lRetVal = JSON.serialize(lstFlowSummary);
        }catch(Exception ex){
            System.debug(LoggingLevel.warn, 'ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
            Throw new AuraHandledException('An error was encountered' + ex + ' STACKTRACE: '+ex.getStackTraceString());
        }
        return lstRetVal;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static List<FlowSummary> getDetailedFlowSummaryList(){
        //This WILL include FullName (FullName) or ObjectType (ObjectName) for the Latest version only
        //OlderVersions may exist under the Latest Version, but they will not have ObjectName or FullName
        //The return value will be a JSON serialized string of List<FlowSummary>
        List<FlowSummary> lstRetVal;
        Try{
            List<FlowClass> lstFlowClass = RestApiUtil.getLatestFlowsDetailed();
            lstRetVal = getFlowSummaryList(lstFlowClass);
            debugPrintResults(lstRetVal);
            //lRetVal = JSON.serialize(lstFlowSummary);
        }catch(Exception ex){
            System.debug(LoggingLevel.warn, 'ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
            Throw new AuraHandledException('An error was encountered' + ex + ' STACKTRACE: '+ex.getStackTraceString());
        }
        return lstRetVal;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static void debugPrintResults(List<FlowSummary> pLstFlowSummary){
        for (FlowSummary myFS:pLstFlowSummary){
            System.debug(LoggingLevel.warn, 'NAME: '+myFS.Name+' VERSION: '+myFS.Version+' ObjectName: '+myFS.ObjectName);
            if (myFS.OlderVersions!=null){
                for (FlowSummary myFSOV:myFS.OlderVersions){
                    System.debug(LoggingLevel.warn, '......OLDER VERSION NAME: '+myFSOV.Name+' OLDER VERSION: '+myFSOV.Version);
                    //System.debug(LoggingLevel.warn, 'OLDER VERSION '+myFSOV);
                }
            }
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    private static List<FlowSummary> getFlowSummaryList(List<FlowClass> pLstFlowClass){
        List<FlowSummary> lstRetVal = new List<FlowSummary>();
        Set<String> setUserIds = new Set<String>();
        for (FlowClass myFC:pLstFlowClass){
            setUserIds.add(myFC.LastModifiedById);
            setUserIds.add(myFC.CreatedById); 
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
                FlowSummary tempChild = buildFlowSummary(thisOlderVersion);
                tempChild.ObjectName = '';
                myFS.OlderVersions.add(tempChild);
            }
        }
        myFS.recId = pFlowClass.Id;
        myFS.Name = pFlowClass.MasterLabel;
        myFS.Description = pFlowClass.Description;
        myFS.Status = pFlowClass.Status;
        myFS.LastModifiedDate = pFlowClass.Lastmodifieddate.left(19);
        myFS.LastModifiedByName = mapIdToUser.get(pFlowClass.LastModifiedById).name;
        myFS.CreatedDate = pFlowClass.CreatedDate.left(19);
        myFS.CreatedByName = mapIdToUser.get(pFlowClass.CreatedById).name;
        myFS.Version = pFlowClass.VersionNumber;
        myFS.ObjectName = 'Not Retrieved Yet';

        if (pFlowClass.MetaData!=null && pFlowClass.MetaData.processMetadataValues!=null){
            for (FlowClass.FlowMetadataValue myFMV:pFlowClass.MetaData.processMetadataValues){
                if (myFMV.name=='ObjectType'){
                    myFS.ObjectName = myFMV.value.stringValue;
                }
            }
        }
        myFS.FullName = pFlowClass.FullName;
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
        Public String CreatedDate;
        Public String CreatedByName;
        Public String ObjectName;
        Public String FullName;
        Public String Version;
        Public List<FlowSummary> OlderVersions;
        public FlowSummary(){
            
        }
            
    }


}