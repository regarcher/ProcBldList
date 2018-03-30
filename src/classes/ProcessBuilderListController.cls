public with sharing class ProcessBuilderListController {
    
    @AuraEnabled
    public static String getBaseFlowSummaryList(Integer pLimit){
        //This method will get the most recent versions of Process Builders, regardless of status. 
        //It only brings back fields that are available on the base query
        //This would NOT include MasterLabel (Name) or ObjectType (ObjectName)
        //This begs the question, what field CAN I use to substitute in for MasterLabel?

        //The return value will be a JSON serialized string of List<FlowSummary>
        String lRetVal;
       
        return lRetVal;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static String getDetailedFlowSummaryList(Integer pLimit){
        //this method will get ALL fields for all most recent versions of Process Builders regardless of status
        //This would NOT include MasterLabel (Name) or ObjectType (ObjectName)
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
        List<FlowSummary> lstRetVal = new List<FlowSummary>();
        Set<String> lstUserIds = new Set<String>();
        Map<ID, User> mapIdToUser = new Map<ID,User>();
        for (FlowClass myFC:pLstFlowClass){
            System.debug(LoggingLevel.warn, 'reggie myFC: '+myFC);
            lstUserIds.add(myFC.LastModifiedById); 
        }

        mapIdToUser.putAll([select id, name from user where id in :lstUserIds]);

        //
        for (FlowClass myFC:pLstFlowClass){
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
        return lstRetVal;

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