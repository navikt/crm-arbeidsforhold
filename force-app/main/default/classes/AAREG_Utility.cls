public with sharing class AAREG_Utility {
    private static AAREG_Utility instance;
    private String threadRecordTypeId;

    private AAREG_Utility() {
        /* threadRecordTypeId = [SELECT Id FROM RecordType WHERE developerName = 'AAREG_Thread']?.Id; */
        List<AAREG_Setting__mdt> valueCMList = (List<AAREG_Setting__mdt>) new CustomMetadataDAO()
            .getCustomMetadataRecords(
                'SELECT Value__c FROM AAREG_Setting__mdt WHERE DeveloperName = \'ThreadRecordTypeName\''
            );

        AAREG_Setting__mdt name;
        if (valueCMList.size() > 0) {
            name = valueCMList[0];
        }
        threadRecordTypeId = [SELECT Id FROM RecordType WHERE developerName = :name?.Value__c]?.Id;
    }

    public static AAREG_Utility getInstance() {
        if (instance == null) {
            instance = new AAREG_Utility();
        }
        return instance;
    }

    public String getThreadRecordTypeId() {
        return threadRecordTypeId;
    }
}
