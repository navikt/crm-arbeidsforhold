/**
 * Shared test-data factory for Aa-registeret Apex tests. Provides reusable builders
 * for Accounts, applications, agreements, decisions, and related records so tests
 * do not each redefine the same fixture data.
 *
 * @author Jordan Mathews
 * @author Ann Kristin Olsen
 * @author Erik Fladby
 * @since July 2021
 * @group AAREG Utility
 */
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
            INT_Industry__c = 'Generell offentlig administrasjon',
            INT_IndustryCode__c = '84.110',
            INT_OrganizationNumber__c = '921133642',
            INT_OrganizationalStructure__c = 'KOMM',
            INT_SectorCode__c = '6500',
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
            INT_Industry__c = 'Administrasjon av trygdeordninger underlagt offentlig forvaltning',
            INT_IndustryCode__c = '84.300',
            INT_OrganizationNumber__c = '940415683',
            INT_OrganizationalStructure__c = 'ORGL',
            INT_SectorCode__c = '6100',
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
            INT_Industry__c = 'Distribusjon av elektrisitet',
            INT_IndustryCode__c = '35.140',
            INT_OrganizationNumber__c = '923934138',
            INT_OrganizationalStructure__c = 'AS',
            INT_SectorCode__c = '2100',
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
            INT_Industry__c = 'Generell offentlig administrasjon',
            INT_IndustryCode__c = '84.110',
            INT_OrganizationNumber__c = '929882989',
            INT_OrganizationalStructure__c = 'FYLK',
            INT_SectorCode__c = '6500',
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
            INT_Industry__c = 'Generell offentlig administrasjon',
            INT_IndustryCode__c = '84.110',
            INT_OrganizationNumber__c = '929882989',
            INT_OrganizationalStructure__c = 'FYLK',
            INT_SectorCode__c = '6500',
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
        accList.add(
            new Account(
                Name = 'KOMMUNE',
                INT_Industry__c = 'Generell offentlig administrasjon',
                INT_IndustryCode__c = '84.110',
                INT_OrganizationNumber__c = '921133642',
                INT_OrganizationalStructure__c = 'KOMM',
                INT_SectorCode__c = '6500',
                ShippingStreet = 'Kommunegata 123',
                ShippingPostalCode = '0211',
                ShippingCity = 'Oslo'
            )
        );
        accList.add(
            new Account(
                Name = 'PENSJON',
                INT_Industry__c = 'Administrasjon av trygdeordninger underlagt offentlig forvaltning',
                INT_IndustryCode__c = '84.300',
                INT_OrganizationNumber__c = '940415683',
                INT_OrganizationalStructure__c = 'ORGL',
                INT_SectorCode__c = '6100',
                ShippingStreet = 'Pensjonveien 123',
                ShippingPostalCode = '0211',
                ShippingCity = 'Oslo'
            )
        );
        accList.add(
            new Account(
                Name = 'EL',
                INT_Industry__c = 'Distribusjon av elektrisitet',
                INT_IndustryCode__c = '35.140',
                INT_OrganizationNumber__c = '923934138',
                INT_OrganizationalStructure__c = 'AS',
                INT_SectorCode__c = '2100',
                ShippingStreet = 'El veien 123',
                ShippingPostalCode = '0211',
                ShippingCity = 'Oslo'
            )
        );
        accList.add(
            new Account(
                Name = 'Fylke',
                INT_Industry__c = 'Generell offentlig administrasjon',
                INT_IndustryCode__c = '84.110',
                INT_OrganizationNumber__c = '929882989',
                INT_OrganizationalStructure__c = 'FYLK',
                INT_SectorCode__c = '6500',
                ShippingStreet = 'Fylkgata 123',
                ShippingPostalCode = '0211',
                ShippingCity = 'Oslo'
            )
        );
        return accList;
    }

    private static Application__c buildApplication(Account acc, String organizationStructure, String email) {
        Id devRecordTypeId = SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
            .get('Aa_RegisterAccess')
            .getRecordTypeId();

        return new Application__c(
            Account__c = acc.Id,
            RecordTypeId = devRecordTypeId,
            AA_AccessTypes__c = 'Access OTP',
            OrganizationStructure__c = organizationStructure,
            TermsOfUse__c = true,
            DataProcessorName__c = 'Test Processor',
            DataProcessorOrganizationNumber__c = '987654321',
            Email__c = email,
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
    }

    /**
     * Creates and returns a new County Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created County Application record.
     */
    public static Application__c getApplicationCounty(Account acc) {
        return buildApplication(acc, 'County', 'brukerFylke@example.com');
    }

    /**
     * Creates and returns a new State Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created State Application record.
     */
    public static Application__c getApplicationState(Account acc) {
        return buildApplication(acc, 'State', 'brukerStat@example.com');
    }

    /**
     * Creates and returns a new Electricity-Supervision Application__c record
     * linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Electricity Supervision Application record.
     */
    public static Application__c getApplicationEL(Account acc) {
        return buildApplication(acc, 'Electricity Supervision', 'brukerEl@example.com');
    }

    /**
     * Creates and returns a new Pension Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Pension Application record.
     */
    public static Application__c getApplicationPension(Account acc) {
        return buildApplication(acc, 'Pension', 'brukerPension@example.com');
    }

    /**
     * Creates and returns a new Municipality Application__c record linked to the given Account.
     *
     * @param acc The Account to associate with the Application.
     * @return Application__c - A newly created Municipality Application record.
     */
    public static Application__c getApplicationMunicipality(Account acc) {
        return buildApplication(acc, 'Municipality', 'brukerMunicipality@example.com');
    }

    /**
     * Creates and returns a list of County ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of County basis-code records.
     */
    private static ApplicationBasisCode__c buildBasisCode(
        Application__c app,
        String organizationType,
        String processingBasis,
        Boolean apiAccess,
        Boolean onlineAccess,
        Boolean extractionAccess,
        String legalBasisValue,
        String purposeValue,
        String otherLegalBasis,
        String otherPurpose
    ) {
        ApplicationBasisCode__c record = new ApplicationBasisCode__c(
            Application__c = app.Id,
            API_Access__c = apiAccess,
            Extraction_Access__c = extractionAccess,
            Online_Access__c = onlineAccess,
            ProcessingBasis__c = processingBasis,
            OrganizationType__c = organizationType,
            OtherLegalBasis__c = otherLegalBasis,
            OtherPurpose__c = otherPurpose
        );

        if (organizationType == 'County') {
            record.LegalBasisCounty__c = legalBasisValue;
            record.PurposeCounty__c = purposeValue;
        } else if (organizationType == 'Electricity Supervision') {
            record.LegalBasisElectricitySupervision__c = legalBasisValue;
            record.PurposeElectricitySupervision__c = purposeValue;
        } else if (organizationType == 'Pension') {
            record.LegalBasisPension__c = legalBasisValue;
            record.PurposePension__c = purposeValue;
        } else if (organizationType == 'Municipality') {
            record.LegalBasisMunicipality__c = legalBasisValue;
            record.PurposeMunicipality__c = purposeValue;
        } else if (organizationType == 'State') {
            record.LegalBasisState__c = legalBasisValue;
            record.PurposeState__c = purposeValue;
        }

        return record;
    }

    public static List<ApplicationBasisCode__c> getBasisCodeCounty(Application__c app) {
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(
            buildBasisCode(
                app,
                'County',
                'Processing Basis 1',
                true,
                false,
                false,
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Tildeling og kontroll av drosjeløyve',
                null,
                null
            )
        );
        basisCodes.add(
            buildBasisCode(
                app,
                'County',
                'Processing Basis 3',
                true,
                false,
                false,
                'Annet - oppgi i tekstfelt under',
                'Annet - oppgi i tekstfelt under',
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Tildeling og kontroll av drosjeløyve'
            )
        );

        basisCodes.add(
            buildBasisCode(
                app,
                'County',
                'Processing Basis 2',
                false,
                true,
                false,
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Kontroll av helsepersonell - tilsynssaker',
                null,
                null
            )
        );
        return basisCodes;
    }

    /**
     * Creates and returns a list of Electricity-Supervision ApplicationBasisCode__c
     * records linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Electricity-Supervision basis-code records.
     */
    public static List<ApplicationBasisCode__c> getBasisCodeEL(Application__c app) {
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(
            buildBasisCode(
                app,
                'Electricity Supervision',
                'Processing Basis 1',
                true,
                false,
                false,
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Tilsyn med elektriske anlegg og elektrisk utstyr',
                null,
                null
            )
        );
        basisCodes.add(
            buildBasisCode(
                app,
                'Electricity Supervision',
                'Processing Basis 2',
                false,
                true,
                false,
                'Annet - oppgi i tekstfelt under',
                'Annet - oppgi i tekstfelt under',
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Tilsyn med elektriske anlegg og elektrisk utstyr'
            )
        );
        return basisCodes;
    }

    /**
     * Creates and returns a list of Pension ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Pension basis-code records.
     */
    public static List<ApplicationBasisCode__c> getBasisCodePension(Application__c app) {
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(
            buildBasisCode(
                app,
                'Pension',
                'Processing Basis 1',
                true,
                false,
                false,
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav b',
                'Arbeid med administrasjon knyttet til OU-samordningen',
                null,
                null
            )
        );
        basisCodes.add(
            buildBasisCode(
                app,
                'Pension',
                'Processing Basis 2',
                false,
                true,
                false,
                'Annet - oppgi i tekstfelt under',
                'Annet - oppgi i tekstfelt under',
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav b',
                'Arbeid med administrasjon knyttet til OU-samordningen'
            )
        );
        return basisCodes;
    }

    /**
     * Creates and returns a list of Municipality ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of Municipality basis-code records.
     */
    public static List<ApplicationBasisCode__c> getBasisCodeMunicipality(Application__c app) {
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(
            buildBasisCode(
                app,
                'Municipality',
                'Processing Basis 1',
                true,
                false,
                false,
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Behandling av startlån/boligtilskudd',
                null,
                null
            )
        );
        basisCodes.add(
            buildBasisCode(
                app,
                'Municipality',
                'Processing Basis 2',
                false,
                true,
                false,
                'Annet - oppgi i tekstfelt under',
                'Annet - oppgi i tekstfelt under',
                'FOR-2008-08-18-942 om Arbeidsgiver- og arbeidstakerregisteret § 10 bokstav f',
                'Behandling av startlån/boligtilskudd'
            )
        );
        return basisCodes;
    }

    /**
     * Creates and returns a list of State ApplicationBasisCode__c records
     * linked to the given Application.
     *
     * @param app The Application to associate with the basis codes.
     * @return List<ApplicationBasisCode__c> - A list of State basis-code records.
     */
    public static List<ApplicationBasisCode__c> getBasisCodeState(Application__c app) {
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(
            buildBasisCode(
                app,
                'State',
                'Processing Basis 1',
                true,
                false,
                false,
                'LOV-2002-06-14-20 Brann- og eksplosjonsvernloven § 33',
                'Kontroll av virksomheter som benytter eksplosiver.',
                null,
                null
            )
        );
        basisCodes.add(
            buildBasisCode(
                app,
                'State',
                'Processing Basis 2',
                true,
                false,
                false,
                'Annet - oppgi i tekstfelt under',
                'Annet - oppgi i tekstfelt under',
                'LOV-2002-06-14-20 Brann- og eksplosjonsvernloven § 33',
                'Kontroll av virksomheter som benytter eksplosiver.'
            )
        );
        return basisCodes;
    }

    private static RelatedContact__c buildRelatedContact(
        Application__c app,
        String name,
        String phone,
        String email,
        Boolean agreementNotifications,
        Boolean changeNotifications,
        Boolean errorMessageNotifications,
        Boolean securityNotifications
    ) {
        return new RelatedContact__c(
            Name = name,
            Application__c = app.Id,
            Phone__c = phone,
            Email__c = email,
            AgreementNotifications__c = agreementNotifications,
            ChangeNotifications__c = changeNotifications,
            ErrorMessageNotifications__c = errorMessageNotifications,
            SecurityNotifications__c = securityNotifications
        );
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
        relatedContacts.add(
            buildRelatedContact(
                app,
                'Kommunekontakt 1',
                '12345678',
                'Kommunekontakt1@example.com',
                true,
                true,
                false,
                false
            )
        );
        relatedContacts.add(
            buildRelatedContact(
                app,
                'Kommunekontakt 2',
                '87654321',
                'Kommunekontakt2@example.com',
                false,
                false,
                true,
                true
            )
        );
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
