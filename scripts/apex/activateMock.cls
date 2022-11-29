//Activate mock settings for all profiles

List<API_Controller_Mock_Settings__c> mockSettings = new List<API_Controller_Mock_Settings__c>();

for (Profile p : [SELECT Id FROM Profile]) {
    API_Controller_Mock_Settings__c mockSetting = API_Controller_Mock_Settings__c.getInstance(p.Id);
    mockSetting.Status__c = 'OK';
    mockSetting.Status_Code__c = '200';
    mockSetting.Use_Mock__c = true;
    mockSettings.add(mockSetting); 
}
upsert mockSettings;