/**
 * This is a utility class for Arbeidsforhold related functionality. It implements
 * the Singleton design pattern to ensure that only one instance of the utility class
 * exists throughout the transaction. This is particularly useful for managing various
 * configurations and settings related to Arbeidsforhold, such as retrieving the RecordTypeId for threads. Inspired by
 * the need to access custom metadata configs efficiently and consistently across different parts of the application.
 * <br><br>
 *
 * @author Ashish Misra
 * @since Februar 2026
 * @group AAREG Utility
 */
public with sharing class AAREG_Utility {

    
    /**
     * The singleton instance of the AAREG_Utility class.
     */
    @TestVisible
    private static AAREG_Utility instance;
    /**
     * Holds the RecordType Id for `Thread` records.    
     */
    @TestVisible
    private Id threadRecordTypeId;

    /**
     * Is used to initialize the AAREG_Utility singleton instance.
     * The method retrieves the RecordType for threads based on custom metadata configuration
     * and then RecordTypeId from RecordType object based on record type in custom meta data.
     * @return void
     * @example
     * {@code
     * AAREG_Utility aaregConstructor = new AAREG_Utility();
     * }
     */
    @TestVisible
    private AAREG_Utility() {
        List<AAREG_Setting__mdt> valueCMList = (List<AAREG_Setting__mdt>) new CustomMetadataDAO()
            .getCustomMetadataRecords(
                'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\''
            );

        AAREG_Setting__mdt name;
        if (valueCMList.size() > 0) {
            name = valueCMList[0];
        }

        if (Schema.sObjectType.RecordType.isAccessible() && name != null) {
            threadRecordTypeId = [SELECT Id FROM RecordType WHERE developerName = :name?.Value__c]?.Id;
        }
    }

    /**
     * Is used to initialize the AAREG_Utility singleton instance.
     * If the instance is null, it creates a new instance; otherwise, it returns the existing instance.
     * In this way, it ensures that only one instance of the utility class exists throughout the transaction.
     * In addition, it provides a centralized point of access to the utility methods and properties.
     * Which is particularly useful for managing various configurations and settings related to Arbeidsforhold.
     * @return AAREG_Utility - The singleton instance of the AAREG_Utility class.
     * @example
     * {@code
     * AAREG_Utility util = AAREG_Utility.getInstance();
     * }
     */
    public static AAREG_Utility getInstance() {
        if (instance == null) {
            instance = new AAREG_Utility();
        }
        return instance;
    }

    /**
     * Is used to return `Thread`  RecordType Id.
     * @return Id - The RecordType Id for `Thread`.
     * @example
     * {@code
     * Id threadRTId = AAREG_Utility.getInstance().getThreadRecordTypeId();
     * }
     */
    public Id getThreadRecordTypeId() {
        return threadRecordTypeId;
    }
}
