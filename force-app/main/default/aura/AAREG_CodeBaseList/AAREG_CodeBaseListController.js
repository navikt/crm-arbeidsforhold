({
    fetchCodeBaseList : function(component, event, helper) {
		var codeList = component.get("c.getCodeBaseList");
        codeList.setParams({
            recordId:component.get("v.recordId")
        });
        
        codeList.setCallback(this, function(data){
            	component.set("v.codeBaseList", data.getReturnValue());
            });
        $A.enqueueAction(codeList);
    }
})