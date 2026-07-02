@IsTest
public with sharing class AAREG_TestDataFactory {

    /** Account **/
    /**
     * Creates and returns a new Account instance for testing purposes.
     * 
     * @return Account - A newly created Account instance.
     */
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
    
    /**
     * Creates and returns a new Account instance representing a municipality (KOMM)
     * for testing purposes.
     *
     * @return Account - A newly created municipality Account instance.
     */
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
  
  /**
     * Creates and returns a new Account instance representing a pension organization
     * for testing purposes.
     *
     * @return Account - A newly created pension Account instance.
     */
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

  /**
     * Creates and returns a new Account instance representing an electricity supervision
     * organization (AS) for testing purposes.
     *
     * @return Account - A newly created electricity-supervision Account instance.
     */
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
    
    /**
     * Creates and returns a new Account instance representing a county (FYLK)
     * for testing purposes.
     *
     * @return Account - A newly created county Account instance.
     */
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
        
    /**
     * Creates and returns a new Account instance representing a state organization
     * for testing purposes.
     *
     * @return Account - A newly created state Account instance.
     */
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
  
  /**
     * Creates and returns a list of Account instances covering all supported
     * organization types (Municipality, Pension, Electricity, County) for testing.
     *
     * @return List<Account> - A list of newly created Account instances.
     */ 
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
  
  /**
     * Creates and returns a new County Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created County Application record.
     */
  public static Application__c getApplicationCounty(Account acc) {
      
      Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      RecordTypeId = devRecordTypeId,
      AA_AccessTypes__c ='Access OTP',
      OrganizationStructure__c = 'County',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerFylke@example.com',
      Casehandler_Status__c = 'New',
      Status__c = 'New',
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
  
   /**
     * Creates and returns a new State Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created State Application record.
     */
  public static Application__c getApplicationState(Account acc) {
      
      Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      RecordTypeId = devRecordTypeId,
      AA_AccessTypes__c = 'Access OTP',
      OrganizationStructure__c = 'State',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerStat@example.com',
      Casehandler_Status__c = 'New',
        Status__c = 'New',
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
  
  /**
     * Creates and returns a new Electricity-Supervision Application__c record
     * linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Electricity Supervision Application record.
     */
  public static Application__c getApplicationEL(Account acc) {
      
       Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      RecordTypeId = devRecordTypeId,
      AA_AccessTypes__c = 'Access OTP',
      OrganizationStructure__c = 'Electricity Supervision',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerEl@example.com',
      Casehandler_Status__c = 'New',
        Status__c = 'New',
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
   
  /**
     * Creates and returns a new Pension Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Pension Application record.
     */
  public static Application__c getApplicationPension(Account acc) {
       Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      RecordTypeId = devRecordTypeId,
      AA_AccessTypes__c = 'Access OTP',
      OrganizationStructure__c = 'Pension',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerPension@example.com',
      Casehandler_Status__c = 'New',
        Status__c = 'New',
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
  
  /**
     * Creates and returns a new Municipality Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Municipality Application record.
     */
  public static Application__c getApplicationMunicipality(Account acc) {
      
      Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
      .get('Aa_RegisterAccess')
      .getRecordTypeId();
      
    Application__c application = new Application__c(
      Account__c = acc.id,
      RecordTypeId = devRecordTypeId,
      AA_AccessTypes__c = 'Access OTP',
      OrganizationStructure__c = 'Municipality',
      TermsOfUse__c = true,
      DataProcessorName__c = 'Test Processor',
      DataProcessorOrganizationNumber__c = '987654321',
      Email__c = 'brukerMunicipality@example.com',
      Casehandler_Status__c = 'New',
        Status__c = 'New',
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
  
  /**
     * Creates and returns a list of County ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of County basis-code records.
     */ 
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
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 3',
            OrganizationType__c = 'County',
            OtherLegalBasis__c= 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            OtherPurpose__c = 'Tildeling og kontroll av drosjeløyve',
            LegalBasisCounty__c ='Annet - oppgi i tekstfelt under' ,
            PurposeCounty__c ='Annet - oppgi i tekstfelt under'
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
    
    /**
     * Creates and returns a list of Electricity-Supervision ApplicationBasisCode__c
     * records linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Electricity-Supervision basis-code records.
     */
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
         basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = false,
            Extraction_Access__c = false,
            Online_Access__c = true,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'Electricity Supervision',
            OtherLegalBasis__c = 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            OtherPurpose__c = 'Tilsyn med elektriske anlegg og elektrisk utstyr',
            LegalBasisElectricitySupervision__c ='Annet - oppgi i tekstfelt under' ,
            PurposeElectricitySupervision__c ='Annet - oppgi i tekstfelt under'
        ));
        return basisCodes;
    }
    
    /**
     * Creates and returns a list of Pension ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Pension basis-code records.
     */
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
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = false,
            Extraction_Access__c = false,
            Online_Access__c = true,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'Pension',
            OtherLegalBasis__c= 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav b',
            OtherPurpose__c = 'Arbeid med administrasjon knyttet til OU-samordningen',
            LegalBasisPension__c ='Annet - oppgi i tekstfelt under' ,
            PurposePension__c ='Annet - oppgi i tekstfelt under'
        ));
        return basisCodes;
    }
    
    /**
     * Creates and returns a list of Municipality ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Municipality basis-code records.
     */
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
         basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = false,
            Extraction_Access__c = false,
            Online_Access__c = true,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'Pension',
            OtherLegalBasis__c= 'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
            OtherPurpose__c = 'Behandling av startlån/boligtilskudd',
            LegalBasisMunicipality__c ='Annet - oppgi i tekstfelt under' ,
            PurposeMunicipality__c ='Annet - oppgi i tekstfelt under'
        ));
        return basisCodes;
    }
    
     /**
     * Creates and returns a list of State ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of State basis-code records.
     */
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
        basisCodes.add(new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = true,
            Extraction_Access__c = false,
            Online_Access__c = false,
            ProcessingBasis__c = 'Processing Basis 2',
            OrganizationType__c = 'State',
            OtherLegalBasis__c= 'LOV-2002-06-14-20 Brann- og eksplosjonsvernloven § 33',
            OtherPurpose__c = 'Kontroll av virksomheter som benytter eksplosiver.',
            LegalBasisState__c ='Annet - oppgi i tekstfelt under' ,
            PurposeState__c ='Annet - oppgi i tekstfelt under'
        ));
        return basisCodes;
    }
    
  /**
     * Creates and returns a list of RelatedContact__c records linked to the given Application,
     * representing contact persons associated with the application.
     *
     * @param app The Application to associate with the related contacts.
     * @return List<RelatedContact__c> - A list of newly created related-contact records.
     */
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

  /**
   * Creates and returns a new Agreement__c record associated with the specified Account.
   *
   * @param accountId The ID of the Account to associate with the Agreement__c record.
   * @return A new Agreement__c record linked to the provided Account ID.
   */
  public static Agreement__c getAgreement(Id accountId) {
    Agreement__c agreement = new Agreement__c(
      Account__c = accountId,
      Status__c = 'Active',
      APIAccess__c = true,
      ExtractionAccess__c = true
    );
    return agreement;
  }

  

  /**
   * Generates and returns a sample Inquiry__c record for testing purposes.
   *
   * @return Inquiry__c - A sample Inquiry__c record.
   */
  public static Inquiry__c getInquiry() {
    Inquiry__c inquiry = new Inquiry__c(
      InquiryDescription__c = 'Test Description',
      Status__c = 'New',
      Email__c = 'testperson@test33.no',
      TypeOfInquiry__c = 'Endringsbehov'
    );
    return inquiry;
  }

 

  /**
   * Retrieves a deleted Account record for testing purposes.
   * This method is typically used to simulate scenarios involving deleted records.
   *
   * @return Account - A deleted Account record.
   */
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

  /**
   * Retrieves a standard User record for testing purposes.
   * This method can be used to create or fetch a User with default attributes
   * suitable for standard test scenarios.
   *
   * @return User - A User record with standard attributes.
   */
  public static User getStandardUser() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = new User(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'John.Doe@nav.no',
      Username = 'testuser@example.com.' + System.currentTimeMillis(),
      Alias = 'j.doe',
      LanguageLocaleKey = 'no',
      LocaleSidKey = 'no_NO',
      TimeZoneSidKey = 'Europe/Paris',
      EmailEncodingKey = 'UTF-8',
      ProfileId = profile.Id,
      Department = '1',
      LastUsedOrganization__c = '929882989',
      CRM_NAV_Ident__c = 'test123'
    );
    return user;
  }

  /**
     * Creates and returns a new ContentVersion record with sample data for testing purposes.
     *
     * @return ContentVersion - A newly created ContentVersion record.
     */
  public static ContentVersion getContentVersion() {
    String data = 'Test Data';
    ContentVersion contentVersion = new ContentVersion(
      VersionData = EncodingUtil.base64Decode(data),
      Title = 'TestFile.html',
      PathOnClient = 'Test File'
    );
    return contentVersion;
  }

  /**
     * Creates and returns a ContentDocumentLink record linking an existing ContentDocument
     * to a given entity.
     *
     * @param contentDocumentId The ID of the ContentDocument to link.
     * @param linkedEntity      The ID of the entity (record) to link the document to.
     * @return ContentDocumentLink - A newly created ContentDocumentLink record.
     */
  public static ContentDocumentLink getContentDocumentLink(Id contentDocumentId, Id linkedEntity) {
    ContentDocumentLink documentLink = new ContentDocumentLink(
      LinkedEntityId = linkedEntity,
      ContentDocumentId = contentDocumentId,
      ShareType = 'I'
    );
    return documentLink;
  }

  /**
     * Creates a new ContentVersion, retrieves its ContentDocumentId, and returns
     * a ContentDocumentLink linking it to the provided entity.
     *
     * @param linkedEntity The ID of the entity (record) to link the document to.
     * @return ContentDocumentLink - A newly created ContentDocumentLink record.
     */
  public static ContentDocumentLink getContentDocumentLink(Id linkedEntity) {
    ContentVersion content = getContentVersion();
    insert content;

    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];

    return getContentDocumentLink(version.ContentDocumentId, linkedEntity);
  }
  
  /**
     * Inner helper class running in `without sharing` context to allow assignment
     * of permission sets regardless of the calling context's sharing rules.
     */
  private without sharing class PermSetAssigner {
    /**
     * Assigns a permission set to a user.
     *
     * @param userId The ID of the user to whom the permission set will be assigned.
     * @param permSetName The name of the permission set to assign.
     */
    private void assign(Id userId, String permSetName) {
      PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
      insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
    }
  }

  /**
     * Assigns a permission set to a user by delegating to the without-sharing
     * inner helper class. Useful in tests where the running user lacks rights
     * to insert PermissionSetAssignment directly.
     *
     * @param userId      The ID of the user to receive the permission set.
     * @param permSetName The API name of the permission set to assign.
     */
  public static void assignPermissionSet(Id userId, String permSetName) {
    new PermSetAssigner().assign(userId, permSetName);
  } 

}