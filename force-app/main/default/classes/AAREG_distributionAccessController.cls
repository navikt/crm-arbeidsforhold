public class AAREG_distributionAccessController {
@InvocableMethod(
        label='AAREG - Distribution integration'
        description='PUT/DELETE access'
        category='Distribution'
    )
    public static List<FlowOutputs> handleRequest(List<FlowInputs> request) {
       List<FlowOutputs> returnList = new List<FlowOutputs>();
        Boolean statusCodeValue;
       String jsonS;
        
        switch on(request[0].referenceType){
            when 'DELETE'{
                jsonS= AAREG_distributionAccessRequest.generateJson(request[0].refAccessType);
              	AAREG_distributionAccessRequest.generateHeaderToDistribution(request[0].refOrganizationNumber,'DEL_AAREG_DIST_TILGANG',jsonS);
                //returnList.add(Boolean.valueOf(statusCodeValue));
            }
            when 'PUT'{
                jsonS=AAREG_distributionAccessRequest.generateJson(request[0].refAccessType);
                AAREG_distributionAccessRequest.generateHeaderToDistribution(request[0].refOrganizationNumber,'PUT_AAREG_DIST_TILGANG',jsonS);
                //returnList.add(Boolean.valueOf(statusCodeValue));
            }
        }
        return returnList;

    }
    
    public class FlowInputs{
        @InvocableVariable(label='Agreement id' required=true)
        public Id referenceId;
    	@InvocableVariable(label='PUT OR DELETE' required=true)
        public String referenceType;
        @InvocableVariable(label='Access type' required=true)
        public String refAccessType;
    	@InvocableVariable(label='' required=true)
     	public String refOrganizationNumber;
    }
    
    public class FlowOutputs{
        @InvocableVariable
        public Boolean success;
        
        public FlowOutputs(){
            this.success = false;
        }
        
        public FlowOutputs(Boolean success){
            this.success = success;
        }
    } 
}