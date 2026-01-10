@isTest
public class AAREG_AgreementControllerTest {
  @TestSetup
  static void makeData() {
    Account acct = AAREG_TestDataFactory.getAccount();
    insert acct;

    Application__c application = AAREG_TestDataFactory.getApplication(acct.Id);
    insert application;

    Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
    agreement.Application__c = application.Id;
    insert agreement;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    RelatedContact__c contact = AAREG_TestDataFactory.getRelatedContact();
    RelatedContact__c contactTwo = AAREG_TestDataFactory.getRelatedContact();
    contact.Agreement__c = agreement.Id;
    contactTwo.Agreement__c = agreement.Id;
    contacts.add(contact);
    contacts.add(contactTwo);

    insert contacts;
  }

  @isTest
  static void getAgreementContacts() {
    Agreement__c agreement = [SELECT Id FROM Agreement__c];
    List<RelatedContact__c> contacts;

    Test.startTest();
    contacts = AAREG_AgreementController.getAgreementContacts(agreement.Id);
    Test.stopTest();

    System.assertEquals(2, contacts.size(), 'Confirm that the agreement has two related contacts.');
  }

  @isTest
  static void updateAgreement() {
    Agreement__c agreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c];
    agreement.ExtractionAccess__c = false;

    List<RelatedContact__c> contacts = [SELECT Id, Name FROM RelatedContact__c];
    contacts[0].Name = 'Updated Name';

    List<RelatedContact__c> contactsToUpdate = new List<RelatedContact__c>();
    contactsToUpdate.add(contacts[0]);

    List<RelatedContact__c> contactsToDelete = new List<RelatedContact__c>();
    contactsToDelete.add(contacts[1]);

    Test.startTest();
    AAREG_AgreementController.updateAgreement(agreement, contactsToUpdate, contactsToDelete);
    Test.stopTest();

    List<RelatedContact__c> updatedContactList = [SELECT Id, Name FROM RelatedContact__c];
    Agreement__c updatedAgreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c];

    System.assertEquals(1, updatedContactList.size(), 'Only 1 contact left');
    System.assertEquals('Updated Name', updatedContactList[0].Name, 'Name updated successfully');
    System.assertEquals(false, updatedAgreement.ExtractionAccess__c, 'Agreement Access type changed');
  }

  @isTest
  static void cancelAgreement() {
    Agreement__c agreement = [SELECT Id, Status__c FROM Agreement__c];

    Test.startTest();
    AAREG_AgreementController.cancelAgreement(agreement);
    Test.stopTest();

    Agreement__c updatedAgreement = [SELECT Id, Status__c FROM Agreement__c];

    System.assertEquals('Deactivated', updatedAgreement.Status__c, 'Agreement Deactivated');
  }

}
