({
	loadProcessBuilderListData: function(component) {
        var action = component.get('c.getDetailedFlowSummaryList');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.myFlowSummaryList", response.getReturnValue());
            }
        });
         $A.enqueueAction(action);
        
    }
})