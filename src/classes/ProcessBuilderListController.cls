public with sharing class ProcessBuilderListController {

  
   
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    public static List<FlowSummary> getDetailedFlowSummaryList(){
        //This WILL include FullName (FullName) or ObjectType (ObjectName) for the Latest version only
        //OlderVersions may exist under the Latest Version, but they will not have ObjectName or FullName
        //The return value will be a JSON serialized string of List<FlowSummary>
        List<FlowSummary> lstRetVal;
        Try{
            lstRetVal = FlowSummaryHelper.getDetailedFlowSummaryList();
        }Catch(Exception Ex){
            System.debug(LoggingLevel.warn, 'ex: '+ ex + ' STACKTRACE: '+ex.getStackTraceString());
            Throw new AuraHandledException('An error was encountered' + ex + ' STACKTRACE: '+ex.getStackTraceString());
        }
        return lstRetVal;
    }
   
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



}