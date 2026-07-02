@IsTest
public class AAREG_AgreementControllerTest {
  @TestSetup
  static void makeData() {
    Account acct = AAREG_TestDataFactory.getAccountCounty();
    insert acct;

    Application__c application = AAREG_TestDataFactory.getApplicationCounty(acct);
    insert application;

    List<RelatedContact__c> con = AAREG_TestDataFactory.getRelatedContact(application);
    insert con;

    Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
    agreement.application__c = application.Id;
    insert agreement;

    for(RelatedContact__c r:con){
      r.agreement__c = agreement.Id;
    }
    Update con;
  }

  @IsTest
  static void getAgreementContacts() {
    Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

    Test.startTest();
    List<RelatedContact__c> contacts = AAREG_AgreementController.getAgreementContacts(agreement.Id);
    Test.stopTest();

    System.assertEquals(2, contacts.size(), 'Confirm that the agreement has two related contacts.');
    System.assertEquals('Kommunekontakt 1', contacts[0].Name, 'First contact name should match expected test data.');
  }

  @IsTest
  static void updateAgreement() {
    Agreement__c agreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c LIMIT 1];
    agreement.ExtractionAccess__c = false;

    List<RelatedContact__c> contacts = [SELECT Id, Name, Agreement__c FROM RelatedContact__c ORDER BY Name ASC LIMIT 2];
    contacts[0].Name = 'Updated Name';

    List<RelatedContact__c> contactsToUpdate = new List<RelatedContact__c>{ contacts[0] };
    List<RelatedContact__c> contactsToDelete = new List<RelatedContact__c>{ contacts[1] };

    Test.startTest();
    AAREG_AgreementController.updateAgreement(agreement, contactsToUpdate, contactsToDelete);
    Test.stopTest();

    List<RelatedContact__c> updatedContacts = [SELECT Id, Name, Agreement__c FROM RelatedContact__c WHERE Agreement__c = :agreement.Id];
    Agreement__c updatedAgreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c WHERE Id = :agreement.Id];

    System.assertEquals(1, updatedContacts.size(), 'Only 1 contact left after deletion.');
    System.assertEquals('Updated Name', updatedContacts[0].Name, 'Name updated successfully.');
    System.assertEquals(false, updatedAgreement.ExtractionAccess__c, 'Agreement ExtractionAccess should be updated.');
  }

  @IsTest
  static void cancelAgreement() {
    Agreement__c agreement = [SELECT Id, Status__c, OnlineAccess__c, ExtractionAccess__c, APIAccess__c FROM Agreement__c LIMIT 1];

    Test.startTest();
    AAREG_AgreementController.cancelAgreement(agreement);
    Test.stopTest();

    Agreement__c updatedAgreement = [SELECT Id, Status__c, OnlineAccess__c, ExtractionAccess__c, APIAccess__c, AA_ConfirmedAgreementCancellationDate__c FROM Agreement__c WHERE Id = :agreement.Id];

    System.assertEquals('Deactivated', updatedAgreement.Status__c, 'Agreement should be deactivated.');
    System.assertEquals(false, updatedAgreement.OnlineAccess__c, 'OnlineAccess should be disabled after cancellation.');
    System.assertEquals(false, updatedAgreement.ExtractionAccess__c, 'ExtractionAccess should be disabled after cancellation.');
    System.assertEquals(false, updatedAgreement.APIAccess__c, 'APIAccess should be disabled after cancellation.');
    System.assertEquals(Date.today(), updatedAgreement.AA_ConfirmedAgreementCancellationDate__c, 'Cancellation date should be set to today.');
  }

  
}