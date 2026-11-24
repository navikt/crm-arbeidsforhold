/**
 * Tests «Min profil» and the organization selector for portal users.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelPortalControllerTest {
    private static final String PERMITTED = '910000001';
    private static final String DENIED = '910000002';
    private static final String UNKNOWN = '910000009';

    private class AltinnStub implements IAltinnCalloutService {
        public Object getOrganizations(String personIdent) {
            AltinnCalloutService.AltinnOrganizationsResponse response = new AltinnCalloutService.AltinnOrganizationsResponse();
            response.success = true;
            response.organizations = new List<AltinnCalloutService.Organization>{
                organization(
                    PERMITTED,
                    'Bedrift AS',
                    new List<AltinnCalloutService.Organization>{
                        organization('910000011', 'Avdeling Bergen', null),
                        organization(PERMITTED, 'Duplikat', null)
                    }
                ),
                organization(DENIED, 'Annen Bedrift AS', null)
            };
            AltinnCalloutService.Organization deleted = organization('910000099', 'Slettet AS', null);
            deleted.isDeleted = 'true';
            response.organizations.add(deleted);
            return response;
        }

        public Object getRights(String personIdent, String organizationNumber, String serviceCode) {
            AltinnCalloutService.AltinnRightsResponse response = new AltinnCalloutService.AltinnRightsResponse();
            response.success = true;
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access';
            right.Decision = organizationNumber == DENIED ? 'Deny' : 'Permit';
            response.rights = new List<AltinnCalloutService.Right>{ right };
            return response;
        }
    }

    private static AltinnCalloutService.Organization organization(
        String organizationNumber,
        String name,
        List<AltinnCalloutService.Organization> subunits
    ) {
        AltinnCalloutService.Organization organization = new AltinnCalloutService.Organization();
        organization.organizationNumber = organizationNumber;
        organization.name = name;
        organization.unitType = subunits == null ? 'BEDR' : 'AS';
        organization.isDeleted = 'false';
        organization.subunits = subunits;
        return organization;
    }

    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        insert new List<Account>{
            new Account(Name = 'Bedrift AS', INT_OrganizationNumber__c = PERMITTED),
            new Account(Name = 'Annen Bedrift AS', INT_OrganizationNumber__c = DENIED)
        };
        AAREG_ContactModelTestDataFactory.createPortalUser('Portalsen', '01010112345');
    }

    private static void enableAll() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.ORG_SELECTOR => true,
                AAREG_ContactModelGate.PROFILE => true,
                AAREG_ContactModelGate.CONTEXT_ADDRESS => true
            },
            null
        );
        AAREG_ContactModelPortalController.altinnOverride = new AltinnCalloutService(new AltinnStub());
    }

    private static User portalUser() {
        return [SELECT Id FROM User WHERE LastName = 'Portalsen' AND ContactId != NULL LIMIT 1];
    }

    @IsTest
    static void organizationsAreUniqueSortedAndSkipDeletedUnits() {
        enableAll();
        List<AAREG_ContactModelPortalController.OrganizationOption> options;
        System.runAs(portalUser()) {
            options = AAREG_ContactModelPortalController.getOrganizations();
        }

        System.Assert.areEqual(3, options.size(), JSON.serialize(options));
        System.Assert.areEqual('Annen Bedrift AS', options[0].name, 'Sorted by name');
        System.Assert.areEqual('Avdeling Bergen', options[1].name, 'Subunit included');
        System.Assert.areEqual('Bedrift AS', options[1].parentName, 'Subunit shows its parent');
        System.Assert.areEqual('Bedrift AS', options[2].name, 'Duplicate number keeps the first name');
    }

    @IsTest
    static void switchedOffFeatureIsRejected() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{ AAREG_ContactModelGate.PROFILE => false },
            null
        );
        System.runAs(portalUser()) {
            System.Assert.isFalse(AAREG_ContactModelPortalController.getSettings().profile, 'Profile flag off');
            try {
                AAREG_ContactModelPortalController.getProfile(null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.areEqual('Funksjonen er ikkje slått på.', error.getMessage(), 'Readable message');
            }
        }
    }

    @IsTest
    static void eachContextKeepsItsOwnAddressWithoutFallback() {
        enableAll();
        AAREG_ContactModelPortalController.Profile privateProfile;
        AAREG_ContactModelPortalController.Profile organizationProfile;
        AAREG_ContactModelPortalController.Profile reread;
        System.runAs(portalUser()) {
            privateProfile = AAREG_ContactModelPortalController.saveAddress(null, 'kari@privat.example', '99999999');
            organizationProfile = AAREG_ContactModelPortalController.saveAddress(
                PERMITTED,
                'kari@bedrift.example',
                null
            );
            reread = AAREG_ContactModelPortalController.getProfile(PERMITTED);
        }

        System.Assert.areEqual('kari@privat.example', privateProfile.privateEmail, 'Private address saved');
        System.Assert.isNull(privateProfile.organization, 'No organization context for «Meg selv»');
        System.Assert.areEqual('kari@bedrift.example', organizationProfile.organization.email, 'Organization address');
        System.Assert.areEqual('kari@privat.example', organizationProfile.privateEmail, 'Private address unchanged');
        System.Assert.isTrue(reread.organization.verified, 'Altinn confirmed the role');
        System.Assert.areEqual('Bedrift AS', reread.organization.name, 'Organization name');

        AccountContactRelation relation = [
            SELECT AAREG_Altinn_Verified_At__c, AAREG_Managed__c
            FROM AccountContactRelation
            WHERE Account.INT_OrganizationNumber__c = :PERMITTED AND Contact.AAREG_Identity_Key__c != NULL
            WITH SYSTEM_MODE
        ];
        System.Assert.isTrue(relation.AAREG_Managed__c, 'Managed relation');
        System.Assert.isNotNull(relation.AAREG_Altinn_Verified_At__c, 'Verification time recorded');
    }

    @IsTest
    static void deniedOrganizationShowsNoAddressAndCannotBeSaved() {
        enableAll();
        AAREG_ContactModelPortalController.Profile profile;
        System.runAs(portalUser()) {
            profile = AAREG_ContactModelPortalController.getProfile(DENIED);
            try {
                AAREG_ContactModelPortalController.saveAddress(DENIED, 'kari@annen.example', null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains('Altinn'), error.getMessage());
            }
        }

        System.Assert.isFalse(profile.organization.verified, 'Not verified');
        System.Assert.isNull(profile.organization.email, 'No address without a confirmed role');
        System.Assert.isNotNull(profile.organization.message, 'Explains why');
        System.Assert.areEqual(
            0,
            [
                SELECT COUNT()
                FROM AAREG_Contact_Point__c
                WHERE Organization__r.INT_OrganizationNumber__c = :DENIED
                WITH SYSTEM_MODE
            ],
            'Nothing saved'
        );
    }

    @IsTest
    static void unknownOrganizationAndInvalidAddressGiveReadableMessages() {
        enableAll();
        AAREG_ContactModelPortalController.Profile profile;
        System.runAs(portalUser()) {
            profile = AAREG_ContactModelPortalController.getProfile(UNKNOWN);
            try {
                AAREG_ContactModelPortalController.saveAddress(null, 'ikkje-ei-adresse', null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains('gyldig'), error.getMessage());
            }
            try {
                AAREG_ContactModelPortalController.saveAddress(UNKNOWN, 'kari@ny.example', null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.isTrue(error.getMessage().contains('finst ikkje'), error.getMessage());
            }
        }

        System.Assert.isTrue(profile.organization.verified, 'Role confirmed');
        System.Assert.isTrue(profile.organization.message.contains('finst ikkje'), profile.organization.message);
    }
}
