public with sharing class FlowClass {
    //reggie, hmmmmm, there are a few ways to do this
    //1. type it all in by hand
    //2. see if my print out will do it for me and I can do some copy-paste
    //Both of the options above fall prey to metadata versions.  I doubt highly that I can
    //dymamically create a class and use it on the fly....but....what are my options for describe?
    //NONE as this fails: /services/data/v41.0/sobjects/Flow/describe/
    //So, it seems I'm stuck with the API guide
    //https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm
    //also helpful is the Flow and Flow definitions .. 
    //https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flow.htm
    ////https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_flowdefinition.htm
	//   
	public String Id;
    public String Description;
    public String FullName;
    public String ManageableState;
    public String MasterLabel;
    public String ProcessType;
    public String VersionNumber;
    public String Status;
    public String Lastmodifieddate;
    public String LastModifiedById;
    
    public MetaData MetaData;
    
    public class MetaData {
        public String description;
        public string interviewLabel;
        public string label;
        public string processType;
        public string startElementReference;
        public string urls;
        public List<FlowClass.FlowActionCall> actionCalls;
        public List<FlowApexPluginCall> apexPluginCalls;
        public List<FlowAssignment> assignments;
        public List<FlowChoice> choices;
        public List<FlowConstant> constants;
        public List<FlowDecision> decisions;
        public List<FlowDynamicChoiceSet> dynamicChoiceSets;
        public List<FlowFormula> formulas;
        public List<FlowLoop> loops;
        public List<FlowMetadataValue> processMetadataValues;
        public List<FlowRecordCreate> recordCreates;
        public List<FlowRecordDelete> recordDeletes;
        public List<FlowRecordLookup> recordLookups;
        public List<FlowRecordUpdate> recordUpdates;
        public List<FlowScreen> screens;
        public List<FlowStage> steps;
        public List<FlowSubflow> subflows;
        public List<FlowTextTemplate> textTemplates;
        public List<FlowVariable> variables;
        public List<FlowWait> waits;
    }
    public class FlowActionCall {
        Public String actionName;
        Public String actionType;
        Public FlowConnector connector;
        Public FlowConnector faultConnector;
        Public List<FlowActionCallInputParameter> inputParameters;
        Public List<FlowActionCallInputParameter> outputParameters;
        
    }
    public class FlowActionCallInputParameter{
        Public string name;
        Public FlowElementReferenceOrValue value;
    }
    
    public class FlowConnector{
        Public string FlowConnector;
    }
    public class FlowApexPluginCall{
        
    }
    public class FlowAssignment{
        
    }
    public class FlowChoice {
        
    }
    public class FlowConstant{
        
    }
    public class FlowDecision {
        Public String defaultConnectorLabel;
        Public FlowConnector defaultConnector;
        Public List<FlowRule> rules;
    }
    public class FlowRule {
        Public string conditionLogic;		
        Public List<FlowCondition> conditions; 
        Public FlowConnector connector;     
        Public string label;	
    }
    public class FlowCondition{
        Public string leftValueReference;
        Public string operator;
        Public FlowElementReferenceOrValue rightValue;
    }
    public class FlowElementReferenceOrValue{
        Public boolean booleanValue;	
        Public dateTime dateTimeValue;	
        Public date dateValue;
        Public string elementReference;	
        Public double numberValue;	
        Public string stringValue;
    }
        
    public class FlowDynamicChoiceSet {
        
    }
    public class FlowFormula {  
    }
    public class FlowLoop {
        
    }
	public class FlowMetadataValue{
        Public string name;
        Public FlowElementReferenceOrValue value;
    } 
    public class FlowRecordCreate {
        
    }
    public class FlowRecordDelete {
        
    }
    public class FlowRecordLookup {
        
    }
    public class FlowRecordUpdate {
    	public FlowConnector connector;	     
    	public FlowConnector faultConnector;	      
    	public List<FlowRecordFilter> filters;	     
    	public List<FlowInputFieldAssignment> inputAssignments;	       
    	//hmmmm, object is reserved!
        //public string object;	        
    	public string inputReference;		        
    }
    public class FlowRecordFilter{
        public string field;
        public string operator;
    }
    public class FlowInputFieldAssignment{
        public string field;
        public FlowElementReferenceOrValue value;
    }
    public class FlowScreen {
    }
    public class FlowStage {
    }   
    public class FlowSubflow {
    }   
    public class FlowTextTemplate {
    }   
    public class FlowVariable{
    	Public String dataType;
		public boolean isCollection;	
		public boolean isInput;	
		public boolean isOutput;	
		public string objectType;	
		public integer scale;	
		public FlowElementReferenceOrValue value;	
    }   
    public class FlowWait{
    }   
    //reggie, here's an example of what Metadata looks like..... 
/*
[{"attributes":{"type":"Flow","url":"/services/data/v41.0/tooling/sobjects/Flow/30146000000YUh3AAG"},"Description":"update some dumb field","FullName":"New_Contact-1","ManageableState":"unmanaged","MasterLabel":"New Contact","ProcessType":"Workflow","Status":"Active","VersionNumber":1,
    
"Metadata":{
        "actionCalls":[],
        "apexPluginCalls":[],
        "assignments":[{
			"assignmentItems":[{
				"assignToReference":"myVariable_waitStartTimeVariable","operator":"Assign",
            	"processMetadataValues":[],
				"value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":"$Flow.CurrentDateTime","numberValue":null,"stringValue":null}}
			],
            "connector":{
                "processMetadataValues":[],"targetReference":"myDecision"
            },
            "description":null,
            "label":"myVariable_waitStartTimeAssignment",
            "locationX":0,
            "locationY":0,
            "name":"myVariable_waitStartTimeAssignment",
            "processMetadataValues":[]}
		],
        "choices":[],
        "constants":[],
        "decisions":[{"defaultConnector":null,"defaultConnectorLabel":"default","description":null,"label":"myDecision","locationX":50,"locationY":0,"name":"myDecision",
            "processMetadataValues":[{"name":"index","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":0.0,"stringValue":null}}],
            "rules":[{"conditionLogic":"and",
                "conditions":[{"leftValueReference":"myVariable_current.LastName","operator":"IsNull",
                    "processMetadataValues":[{"name":"inputDataType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"Boolean"}},
                        {"name":"leftHandSideType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"String"}},
                        {"name":"operatorDataType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"String"}},
                        {"name":"rightHandSideType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"Boolean"}}],"rightValue":{"booleanValue":false,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":null}}],
                "connector":{"processMetadataValues":[],"targetReference":"myRule_1_A1"},"description":null,"label":"has a name","name":"myRule_1",
                    "processMetadataValues":[]}]}
		],
		"description":"update some dumb field",
		"dynamicChoiceSets":[],
		"formulas":[],
		"interviewLabel":"New_Contact-1_InterviewLabel",
		"label":"New Contact",
		"loops":[],
        "processMetadataValues":[{"name":"ObjectType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"Contact"}},
                        {"name":"ObjectVariable","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":"myVariable_current","numberValue":null,"stringValue":null}},
                        {"name":"OldObjectVariable","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":"myVariable_old","numberValue":null,"stringValue":null}},
                        {"name":"TriggerType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"onCreateOnly"}}
		],
		"processType":"Workflow",
        "recordCreates":[],
        "recordDeletes":[],
        "recordLookups":[],
        "recordUpdates":[{"connector":null,"description":null,"faultConnector":null,
			"filters":[{"field":"Id","operator":"EqualTo",
                "processMetadataValues":[{"name":"implicit","value":{"booleanValue":true,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":null}}],
                "value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":"myVariable_current.Id","numberValue":null,"stringValue":null}}
			],
            "inputAssignments":[{"field":"OtherCity","processMetadataValues":[
                    {"name":"dataType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"String"}},
                    {"name":"isRequired","value":{"booleanValue":false,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":null}},
                    {"name":"leftHandSideLabel","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"Other City"}},
                    {"name":"leftHandSideReferenceTo","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":""}},
                    {"name":"rightHandSideType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"String"}}],
                    "value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"Amsterdam"}}],"inputReference":null,"label":"fill other city","locationX":100,"locationY":200,"name":"myRule_1_A1","object":"Contact",
            "processMetadataValues":[
				{"name":"evaluationType","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"always"}},
                {"name":"isChildRelationship","value":{"booleanValue":false,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":null}},
                {"name":"reference","value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":null,"numberValue":null,"stringValue":"[Contact]"}}]}
		],
		"screens":[],
		"startElementReference":"myVariable_waitStartTimeAssignment",
		"steps":[],
		"subflows":[],
		"textTemplates":[],
		"urls":null,
        "variables":[
			{"dataType":"SObject","description":null,"isCollection":false,"isInput":true,"isOutput":true,"name":"myVariable_current","objectType":"Contact","processMetadataValues":[],"scale":null,"value":null},
			{"dataType":"SObject","description":null,"isCollection":false,"isInput":true,"isOutput":false,"name":"myVariable_old","objectType":"Contact","processMetadataValues":[],"scale":null,"value":null},
			{"dataType":"DateTime","description":null,"isCollection":false,"isInput":false,"isOutput":false,"name":"myVariable_waitStartTimeVariable","objectType":null,"processMetadataValues":[],"scale":null,"value":{"booleanValue":null,"dateTimeValue":null,"dateValue":null,"elementReference":"$Flow.CurrentDateTime","numberValue":null,"stringValue":null}}
		],
		"waits":[]}}]



*/
}