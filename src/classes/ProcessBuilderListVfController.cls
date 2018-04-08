public with sharing class ProcessBuilderListVfController {
    Public List<FlowSummary> lstFlowSummary {get;set;}
    Public ProcessBuilderListVfController(){
        try{
            System.debug('ProcessBuilderListVfController constructor');
             lstFlowSummary = FlowSummaryHelper.getDetailedFlowSummaryList();
             if (lstFlowSummary==null || lstFlowSummary.size()==0){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Something Wrong'));
             }
        }catch(Exception Ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Stacktrace: ' + ex.getStackTraceString()));
        }  
    }
}