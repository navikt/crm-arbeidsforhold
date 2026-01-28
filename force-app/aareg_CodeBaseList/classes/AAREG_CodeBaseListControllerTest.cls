@isTest
public class AAREG_CodeBaseListControllerTest {
  @TestSetup
  static void createData() {
    Account acc = new Account();
    acc.Name = 'TestingAA-reg';
    insert acc;

    Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
       Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;
      
      Application__c app = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert app;
      
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeCounty(app);
        insert basisCodes;
  
    ContentVersion file = new ContentVersion();
    String data = 'Dette er innholdet i fila';
    file.Title = 'Dataelementer tilhørende søknad';
    file.PathOnClient = file.Title + '.xlsx';
    file.VersionData = Blob.valueOf(data);
    file.FirstPublishLocationId = app.id;
    insert file;

    Agreement__c agr = new Agreement__c();
    agr.APIAccess__c = true;
    agr.Application__c = app.Id;
    agr.Decision__c = 'Vedtak';
    agr.ExtractionAccess__c = false;
    agr.OnlineAccess__c = false;
    agr.Status__c = 'active';
    insert agr;
  }

  @isTest
  static void testCodeBaseComponent() {
    Application__c appl = [SELECT id FROM Application__c LIMIT 1];
    List<ApplicationBasisCode__c> baseList = AAREG_CodeBaseListController.getCodeBaseList(appl.Id);

    //List should not be empty
    System.assertNotEquals(baseList.size(), 0, 'List should not be empty');

    //Loop through fields to ensure is not null
    for (ApplicationBasisCode__c abc : baseList) {
        if(abc.ProcessingBasis__c =='Processing Basis 1'){
            System.assertEquals(abc.LegalBasisCounty__c,'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f','Legal should be the same');
            System.assertEquals(abc.PurposeCounty__c,'Tildeling og kontroll av drosjeløyve','Purpose should be the same');
        }
        if(abc.ProcessingBasis__c=='Processing Basis 2'){
            System.assertEquals(abc.LegalBasisCounty__c,'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f','Legal should be the same');
            System.assertEquals(abc.PurposeCounty__c,'Kontroll av helsepersonell - tilsynssaker');
        }
    }
  }

  @isTest
  /* test for apex class AAREG_createContentVersionForAgreement*/
  static void testCreateContentVersionOnAgreement() {
    Application__c appl = [SELECT id FROM Application__c LIMIT 1];

    AAREG_createContentVersionForAgreement.FlowInput params = new AAREG_createContentVersionForAgreement.FlowInput();
    params.currRecId = appl.Id;

    Agreement__c agr = [SELECT id FROM Agreement__c LIMIT 1];

    List<ContentVersion> conL = new List<ContentVersion>();
    for (ContentVersion con : [SELECT id, title FROM ContentVersion WHERE FirstPublishLocationId = :agr.id]) {
      System.assertEquals(con.title, 'Dataelementer tilhørende søknad');
    }
  }
}