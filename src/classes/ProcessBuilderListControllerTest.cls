@isTest (SeeAllData=true)
public with sharing class ProcessBuilderListControllerTest {
    static testmethod void testGetDetailedFlowSummaryList(){
        //reggie, yeah, this flat out didn't work as my first tooling call failed...perhaps this isn't allowed in test
        //I'm guessing I'll have to mock it...you can however copy this and perform execute anonymous on it if you wish
        String strSummaryListSerialized = ProcessBuilderListController.getDetailedFlowSummaryList(10);
        System.assertNotEquals(null, strSummaryListSerialized);
        System.assertNotEquals(0, strSummaryListSerialized.length());
        System.debug(LoggingLevel.warn, 'reggie strSummaryListSerialized: '+strSummaryListSerialized);
        List<ProcessBuilderListController.FlowSummary> lstFlowSummary = (List<ProcessBuilderListController.FlowSummary>)JSON.deserialize(strSummaryListSerialized, List<ProcessBuilderListController.FlowSummary>.class);
        System.assertNotEquals(null, lstFlowSummary);
        System.assertNotEquals(0, lstFlowSummary.size());
        for (ProcessBuilderListController.FlowSummary myFS:lstFlowSummary){
            System.debug(LoggingLevel.warn, 'reggie in TEST with FlowSummary: '+myFS);
        }
    }
}