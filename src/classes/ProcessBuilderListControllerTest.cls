@isTest (SeeAllData=true)
public with sharing class ProcessBuilderListControllerTest {
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    static testmethod void testGetBaseFlowSummaryList(){
       //Note that there is logic in the RestApiUtil that if isRunningTest it will go to TestDataFactory instead of attempting
       //to make a callout (which would fail)
        //String strSummaryListSerialized = ProcessBuilderListController.getBaseFlowSummaryList();
        //System.assertNotEquals(null, strSummaryListSerialized);
        //System.assertNotEquals(0, strSummaryListSerialized.length());
        //System.debug(LoggingLevel.warn, 'reggie strSummaryListSerialized: '+strSummaryListSerialized);
        List<FlowSummary> lstFlowSummary = ProcessBuilderListController.getBaseFlowSummaryList();
        System.assertNotEquals(null, lstFlowSummary);
        System.assertNotEquals(0, lstFlowSummary.size());
        for (FlowSummary myFS:lstFlowSummary){
            System.debug(LoggingLevel.warn, 'reggie in TEST with FlowSummary: '+myFS);
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    static testmethod void testGetDetailedFlowSummaryList(){
       //Note that there is logic in the RestApiUtil that if isRunningTest it will go to TestDataFactory instead of attempting
       //to make a callout (which would fail)
        //String strSummaryListSerialized = ProcessBuilderListController.getDetailedFlowSummaryList();
        //System.assertNotEquals(null, strSummaryListSerialized);
        //System.assertNotEquals(0, strSummaryListSerialized.length());
        //System.debug(LoggingLevel.warn, 'reggie strSummaryListSerialized: '+strSummaryListSerialized);
        List<FlowSummary> lstFlowSummary = ProcessBuilderListController.getDetailedFlowSummaryList();
        System.assertNotEquals(null, lstFlowSummary);
        System.assertNotEquals(0, lstFlowSummary.size());
        for (FlowSummary myFS:lstFlowSummary){
            System.debug(LoggingLevel.warn, 'reggie in TEST with FlowSummary: '+myFS);
        }
    }
}