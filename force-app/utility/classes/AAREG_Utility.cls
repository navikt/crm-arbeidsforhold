/**
 * This is a utility class for Arbeidsforhold related functionality. It implements
 * the Singleton design pattern to ensure that only one instance of the utility class
 * exists throughout the transaction. This is particularly useful for managing various
 * configurations and settings related to Arbeidsforhold, such as retrieving the RecordTypeId for threads. Inspired by
 * the need to access custom metadata configs efficiently and consistently across different parts of the application.
 * <br><br>
 * @example
 * {@code
 * AAREG_Utility util = AAREG_Utility.getInstance();
 * Id threadRTId = util.getThreadRecordTypeId();
 * }
 *
 * @author Ashish Misra
 * @since Februar 2026
 * @group AAREG Utility
 */
public with sharing class AAREG_Utility {

    @TestVisible
    private static AAREG_Utility instance;

    @TestVisible
    private Map<String, Id> threadRecordTypeIds = new Map<String, Id>();

    @TestVisible
    private AAREG_Utility() {

        List<AAREG_Setting__mdt> settings = [
            SELECT DeveloperName, Value__c
            FROM AAREG_Setting__mdt
            WHERE DeveloperName LIKE '%ThreadRT'
        ];

        Set<String> developerNames = new Set<String>();

        for (AAREG_Setting__mdt setting : settings) {
            developerNames.add(setting.Value__c);
        }

        Map<String, Id> rtMap = new Map<String, Id>();

        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Thread'
            AND DeveloperName IN :developerNames
        ]) {
            rtMap.put(rt.DeveloperName, rt.Id);
        }

        for (AAREG_Setting__mdt setting : settings) {
            threadRecordTypeIds.put(
                setting.DeveloperName,
                rtMap.get(setting.Value__c)
            );
        }
    }

    public static AAREG_Utility getInstance() {
        if (instance == null) {
            instance = new AAREG_Utility();
        }
        return instance;
    }

    public Id getThreadRecordTypeId() {
        return getThreadRecordTypeId('ThreadRecordTypeName');
    }

    public Id getPersonThreadRecordTypeId() {
        Id personThreadRecordTypeId = getThreadRecordTypeId('PersonThreadRecordTypeName');
        return personThreadRecordTypeId != null ? personThreadRecordTypeId : getThreadRecordTypeId('ThreadRecordTypeName');
    }

    public Id getThreadRecordTypeId(String key) {
        return threadRecordTypeIds.get(key);
    }
}