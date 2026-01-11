@isTest
public with sharing class AAREG_TestDataFactory {

    /** Account **/
    public static Account getAccount() {
    Account acct = new Account(
      Name = 'Test',
      INT_OrganizationNumber__c = '123456789',
      INT_OrganizationalStructure__c = 'ORGL',
      ShippingStreet = 'Test 123',
      ShippingPostalCode = '0211',
      ShippingCity = 'Oslo'
    );
    return acct;
  }
    
  public static Account getAccountMuncipiality() {
    Account acct = new Account(
      Name = 'KOMMUNE',
          INT_Industry__c= 'Generell offentlig administrasjon',
          INT_IndustryCode__c = '84.110',
          INT_OrganizationNumber__c = '921133642',
          INT_OrganizationalStructure__c = 'KOMM',
          INT_SectorCode__c ='6500',
          ShippingStreet = 'Kommunegata 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
    );
    return acct;
  }
    
  public static Account getAccountPension() {
    Account acct = new Account(
      Name = 'PENSJON',
          INT_Industry__c= 'Administrasjon av trygdeordninger underlagt offentlig forvaltning',
          INT_IndustryCode__c = '84.300',
          INT_OrganizationNumber__c = '940415683',
          INT_OrganizationalStructure__c = 'ORGL',
          INT_SectorCode__c ='6100',
          ShippingStreet = 'Pensjonveien 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
    );
    return acct;
  }

    public static Account getAccountEL() {
        Account acct = new Account(
            Name = 'EL',
            INT_Industry__c= 'Distribusjon av elektrisitet',
            INT_IndustryCode__c = '35.140',
            INT_OrganizationNumber__c = '923934138',
            INT_OrganizationalStructure__c = 'AS',
            INT_SectorCode__c ='2100',
            ShippingStreet = 'El veien 123',
            ShippingPostalCode = '0211',
            ShippingCity = 'Oslo'
        );
        return acct;
    }
    
    public static Account getAccountCounty() {
        Account acct = new Account(
          Name = 'Fylke',
          INT_Industry__c= 'Generell offentlig administrasjon',
          INT_IndustryCode__c = '84.110',
          INT_OrganizationNumber__c = '929882989',
          INT_OrganizationalStructure__c = 'FYLK',
          INT_SectorCode__c ='6500',
          ShippingStreet = 'Fylkgata 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
        );
        return acct;
    }
        
    public static Account getAccountState() {
        Account acct = new Account(
          Name = 'Fylke',
          INT_Industry__c= 'Generell offentlig administrasjon',
          INT_IndustryCode__c = '84.110',
          INT_OrganizationNumber__c = '929882989',
          INT_OrganizationalStructure__c = 'FYLK',
          INT_SectorCode__c ='6500',
          ShippingStreet = 'Fylkgata 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
        );
        return acct;
    } 
  
  /** opprettelse av bedrift flere typer**/  
  public static List<Account> getAccountAll() {
    List<Account> accList = new List<Account>();
        accList.add(new Account(
            Name = 'KOMMUNE',
          INT_Industry__c= 'Generell offentlig administrasjon',
          INT_IndustryCode__c = '84.110',
          INT_OrganizationNumber__c = '921133642',
          INT_OrganizationalStructure__c = 'KOMM',
          INT_SectorCode__c ='6500',
          ShippingStreet = 'Kommunegata 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
         
        ));
      accList.add(new Account(
          Name = 'PENSJON',
          INT_Industry__c= 'Administrasjon av trygdeordninger underlagt offentlig forvaltning',
          INT_IndustryCode__c = '84.300',
          INT_OrganizationNumber__c = '940415683',
          INT_OrganizationalStructure__c = 'ORGL',
          INT_SectorCode__c ='6100',
          ShippingStreet = 'Pensjonveien 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
       
      ));
      accList.add(new Account(
          Name = 'EL',
            INT_Industry__c= 'Distribusjon av elektrisitet',
            INT_IndustryCode__c = '35.140',
            INT_OrganizationNumber__c = '923934138',
            INT_OrganizationalStructure__c = 'AS',
            INT_SectorCode__c ='2100',
            ShippingStreet = 'El veien 123',
            ShippingPostalCode = '0211',
            ShippingCity = 'Oslo'
      
      ));
      accList.add(new Account(
      Name = 'Fylke',
          INT_Industry__c= 'Generell offentlig administrasjon',
          INT_IndustryCode__c = '84.110',
          INT_OrganizationNumber__c = '929882989',
          INT_OrganizationalStructure__c = 'FYLK',
          INT_SectorCode__c ='6500',
          ShippingStreet = 'Fylkgata 123',
          ShippingPostalCode = '0211',
          ShippingCity = 'Oslo'
      ));
    return accList;
  }
  
  /** Application **/
  public static Application__c getApplicationCounty(Account acc) {
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      OrganizationStructure__c = 'County',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerFylke@example.com',
      Casehandler_Status__c = 'New',
      IsEmailConfirmationSent__c = true,
      AccountName__c = acc.Name,
      OrganizationNumber__c = acc.INT_OrganizationNumber__c,
      MailingAddress__c = acc.ShippingStreet,
      MailingCity__c = acc.ShippingCity,
      MailingPostalCode__c = acc.ShippingPostalCode,
      ApplicationSubmittedDate__c = Date.today()
    );
    return application;
  }
  
  public static Application__c getApplicationState(Account acc) {
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      OrganizationStructure__c = 'State',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerStat@example.com',
      Casehandler_Status__c = 'New',
      IsEmailConfirmationSent__c = true,
      AccountName__c = acc.Name,
      OrganizationNumber__c = acc.INT_OrganizationNumber__c,
      MailingAddress__c = acc.ShippingStreet,
      MailingCity__c = acc.ShippingCity,
      MailingPostalCode__c = acc.ShippingPostalCode,
      ApplicationSubmittedDate__c = Date.today()
    );
    return application;
  }
    
  public static Application__c getApplicationEL(Account acc) {
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      OrganizationStructure__c = 'Electricity Supervision',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerEl@example.com',
      Casehandler_Status__c = 'New',
      IsEmailConfirmationSent__c = true,
      AccountName__c = acc.Name,
      OrganizationNumber__c = acc.INT_OrganizationNumber__c,
      MailingAddress__c = acc.ShippingStreet,
      MailingCity__c = acc.ShippingCity,
      MailingPostalCode__c = acc.ShippingPostalCode,
      ApplicationSubmittedDate__c = Date.today()
    );
    return application;
  }
    
  public static Application__c getApplicationPension(Account acc) {
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      OrganizationStructure__c = 'Pension',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerPension@example.com',
      Casehandler_Status__c = 'New',
      IsEmailConfirmationSent__c = true,
      AccountName__c = acc.Name,
      OrganizationNumber__c = acc.INT_OrganizationNumber__c,
      MailingAddress__c = acc.ShippingStreet,
      MailingCity__c = acc.ShippingCity,
      MailingPostalCode__c = acc.ShippingPostalCode,
      ApplicationSubmittedDate__c = Date.today()
    );
    return application;
  }
    
  public static Application__c getApplicationMunicipality(Account acc) {
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      OrganizationStructure__c = 'Municipality',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerMunicipality@example.com',
      Casehandler_Status__c = 'New',
      IsEmailConfirmationSent__c = true,
      AccountName__c = acc.Name,
      OrganizationNumber__c = acc.INT_OrganizationNumber__c,
      MailingAddress__c = acc.ShippingStreet,
      MailingCity__c = acc.ShippingCity,
      MailingPostalCode__c = acc.ShippingPostalCode,
      ApplicationSubmittedDate__c = Date.today()
    );
    return application;
  }
  
  /** Application Basis Code **/   
  public static List<ApplicationBasisCode__c> getBasisCodeCounty(Application__c app){
        
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'County',
            LegalBasisCounty__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            PurposeCounty__c = 'Tildeling og kontroll av drosjeløyve'
        ));
      
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = false,
            Extraction_Access__c = false,
            Online_Access__c = true,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'County',
            LegalBasisCounty__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            PurposeCounty__c = 'Kontroll av helsepersonell - tilsynssaker'
        ));
        return basisCodes;
    }
    
     public static List<ApplicationBasisCode__c> getBasisCodeEL(Application__c app){
        
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'Electricity Supervision',
            LegalBasisElectricitySupervision__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            PurposeElectricitySupervision__c = 'Tilsyn med elektriske anlegg og elektrisk utstyr'
        ));
        return basisCodes;
    }
    
    public static List<ApplicationBasisCode__c> getBasisCodePension(Application__c app){
        
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'Pension',
            LegalBasisPension__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav b',
            PurposePension__c = 'Arbeid med administrasjon knyttet til OU-samordningen'
        ));
        return basisCodes;
    }
    
     public static List<ApplicationBasisCode__c> getBasisCodeMunicipality(Application__c app){
        
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'Municipality',
            LegalBasisMunicipality__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            PurposeMunicipality__c = 'Behandling av startlån/boligtilskudd'
        ));
        return basisCodes;
    }
    
    public static List<ApplicationBasisCode__c> getBasisCodeState(Application__c app){
        
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 1',
            OrganizationType__c = 'State',
            LegalBasisState__c = 'LOV-2002-06-14-20 Brann- og eksplosjonsvernloven § 33',
            PurposeState__c = 'Kontroll av virksomheter som benytter eksplosiver.'
        ));
        return basisCodes;
    }
    
  /** opprettelse av kontaktpersoner knyttet til søknad **/
    public static List<RelatedContact__c> getRelatedContact(Application__c app) {
        List<RelatedContact__c> relatedContacts = new List<RelatedContact__c>();
        relatedContacts.add(new RelatedContact__c(
            Name = 'Kommunekontakt 1',
            Application__c = app.Id,
            Phone__c = '12345678',
            Email__c = 'Kommunekontakt1@example.com',
            AgreementNotifications__c = true,
            ChangeNotifications__c = true,
            ErrorMessageNotifications__c = false,
            SecurityNotifications__c = false
        ));
        relatedContacts.add(new RelatedContact__c(
            Name = 'Kommunekontakt 2',
            Application__c = app.Id,
            Phone__c = '87654321',
            Email__c = 'Kommunekontakt2@example.com',
            AgreementNotifications__c = false,
            ChangeNotifications__c = false,
            ErrorMessageNotifications__c = true,
            SecurityNotifications__c = true
        ));
    return relatedContacts;
  }

  public static Agreement__c getAgreement(Id accountId) {
    Agreement__c agreement = new Agreement__c(
      Account__c = accountId,
      Status__c = 'Active',
      APIAccess__c = true,
      OnlineAccess__c = true,
      ExtractionAccess__c = true
    );
    return agreement;
  }

  

  public static Inquiry__c getInquiry() {
    Inquiry__c inquiry = new Inquiry__c(
      InquiryDescription__c = 'Test Description',
      Status__c = 'New',
      Email__c = 'testperson@test33.no',
      TypeOfInquiry__c = 'Endringsbehov'
    );
    return inquiry;
  }

 

  public static Account getDeletedAccount() {
    Account acct = new Account(
      Name = 'Test',
      INT_OrganizationNumber__c = '123456789',
      INT_OrganizationalStructure__c = 'ORGL',
      ShippingStreet = 'Test 123',
      ShippingPostalCode = '0211',
      ShippingCity = 'Oslo',
      EmployerDeletedDate__c = Date.today(),
      IsDeletedEmployer__c = true
    );
    return acct;
  }

  public static User getStandardUser() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = new User(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'John.Doe@nav.no',
      Username = 'John.Doe@nav.no',
      Alias = 'j.doe',
      LanguageLocaleKey = 'no',
      LocaleSidKey = 'no_NO',
      TimeZoneSidKey = 'Europe/Paris',
      EmailEncodingKey = 'UTF-8',
      ProfileId = profile.Id,
      Department = '1',
      LastUsedOrganization__c = '123456789',
      CRM_NAV_Ident__c = 'test123'
    );
    return user;
  }

  public static ContentVersion getContentVersion() {
    String data = 'Test Data';
    ContentVersion contentVersion = new ContentVersion(
      VersionData = EncodingUtil.base64Decode(data),
      Title = 'TestFile.html',
      PathOnClient = 'Test File'
    );
    return contentVersion;
  }

  public static ContentDocumentLink getContentDocumentLink(Id contentDocumentId, Id linkedEntity) {
    ContentDocumentLink documentLink = new ContentDocumentLink(
      LinkedEntityId = linkedEntity,
      ContentDocumentId = contentDocumentId,
      ShareType = 'I'
    );
    return documentLink;
  }

  public static ContentDocumentLink getContentDocumentLink(Id linkedEntity) {
    ContentVersion content = getContentVersion();
    insert content;

    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];

    return getContentDocumentLink(version.ContentDocumentId, linkedEntity);
  }
}