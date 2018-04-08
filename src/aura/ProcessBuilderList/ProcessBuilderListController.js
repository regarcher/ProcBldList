({
    doInit : function(component, event, helper) {
        // Retrieve as all the FlowSummary data that governor limits allow during component initialization
        helper.loadProcessBuilderListData(component);
    }
	
})