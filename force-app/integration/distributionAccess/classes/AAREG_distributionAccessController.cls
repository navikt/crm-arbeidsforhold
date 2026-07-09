/**
 * Controller for handling Distribution Access integration with external APIs.
 * Processes PUT and DELETE requests for distribution access management.
 *
 * @author AAREG Team
 * @version 66
 * @group Integration
 */
public class AAREG_distributionAccessController {
    /**
     * Invocable method to handle distribution access requests from Flow.
     * Supports PUT and DELETE operations for managing access.
     *
     * @param request List of FlowInputs containing operation type and organization data
     * @return List<FlowOutputs> containing the result of the operation
     */
    @InvocableMethod(label='AAREG - Distribution integration' description='PUT/DELETE access' category='Distribution')
    public static List<FlowOutputs> handleRequest(List<FlowInputs> request) {
        List<FlowOutputs> returnList = new List<FlowOutputs>();

        if (request == null || request.isEmpty()) {
            returnList.add(new FlowOutputs(false));
            return returnList;
        }

        String jsonS;
        Boolean success = false;

        try {
            FlowInputs input = request[0];

            if (String.isBlank(input.refOrganizationNumber)) {
                returnList.add(new FlowOutputs(false));
                return returnList;
            }

            jsonS = AAREG_distributionAccessRequest.generateJson(input.refOrganizationNumber);

            switch on (input.referenceType) {
                when 'DELETE' {
                    AAREG_distributionAccessRequest.generateHeaderToDistribution(
                        input.refOrganizationNumber,
                        'DEL_AAREG_DIST_TILGANG',
                        jsonS
                    );
                    success = true;
                }
                when 'PUT' {
                    AAREG_distributionAccessRequest.generateHeaderToDistribution(
                        input.refOrganizationNumber,
                        'PUT_AAREG_DIST_TILGANG',
                        jsonS
                    );
                    success = true;
                }
                when else {
                    success = false;
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error processing distribution access request: ' + e.getMessage(), null);
            logger.publish();
            success = false;
        }

        returnList.add(new FlowOutputs(success));
        return returnList;
    }

    /**
     * Inner class representing input parameters from Flow.
     */
    public class FlowInputs {
        @InvocableVariable(label='Agreement id' required=true)
        public Id referenceId;

        @InvocableVariable(label='PUT OR DELETE' required=true)
        public String referenceType;

        @InvocableVariable(label='Access type' required=true)
        public String refAccessType;

        @InvocableVariable(label='Organization number' required=true)
        public String refOrganizationNumber;
    }

    /**
     * Inner class representing output parameters to Flow.
     */
    public class FlowOutputs {
        @InvocableVariable(label='Operation success')
        public Boolean success;

        /**
         * Default constructor initializing success to false.
         */
        public FlowOutputs() {
            this.success = false;
        }

        /**
         * Constructor with success parameter.
         * @param success Boolean indicating if operation was successful
         */
        public FlowOutputs(Boolean success) {
            this.success = success;
        }
    }
}
