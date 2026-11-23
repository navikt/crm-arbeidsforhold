/**
 * Test data for the Aa-register contact model.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model Test Utility
 */
@IsTest
public with sharing class AAREG_ContactModelTestDataFactory {
    /**
     * Supplies contact model flags to the gate. Flags not in the map are missing.
     *
     * @param enabledByFlag Is_Enabled__c per flag developer name.
     * @param permissionByFlag Required_Custom_Permission__c per flag developer name; may be null.
     */
    public static void setFlags(Map<String, Boolean> enabledByFlag, Map<String, String> permissionByFlag) {
        List<Feature_Flag__mdt> flags = new List<Feature_Flag__mdt>();
        for (String flagName : enabledByFlag.keySet()) {
            flags.add(
                new Feature_Flag__mdt(
                    MasterLabel = flagName,
                    DeveloperName = flagName,
                    Description__c = 'Test fixture',
                    Is_Enabled__c = enabledByFlag.get(flagName),
                    Required_Custom_Permission__c = permissionByFlag?.get(flagName)
                )
            );
        }
        CustomMetadataDAO.customMetadataRecordsMap.put(FeatureToggleBase.METADATA_QUERY, flags);
        AAREG_ContactModelGate.resetFeatureToggle();
    }

    /**
     * Enables or disables only the shadow write flag.
     *
     * @param enabled Whether shadow writing is on.
     */
    public static void setShadowWrite(Boolean enabled) {
        setFlags(new Map<String, Boolean>{ AAREG_ContactModelGate.SHADOW_WRITE => enabled }, null);
    }

    /**
     * Configures AAREG Default Settings org defaults and the contact model primary account.
     *
     * @return Id of the primary account.
     */
    public static Id setUpPrimaryAccount() {
        if (AAREG_Default_Settings__c.getOrgDefaults()?.Id == null) {
            insert as system new AAREG_Default_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Default_Contact__c = '003000000000000AAA'
            );
        }
        return AAREG_ContactModelService.setUpPrimaryAccount();
    }

    /**
     * Creates a minimum-access user, optionally with a permission set.
     *
     * @param lastName Last name, also used to make the username unique.
     * @param permissionSetName Permission set to assign, or null.
     * @return Inserted user.
     */
    public static User createMinimumAccessUser(String lastName, String permissionSetName) {
        Profile minimumAccessProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        String unique = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 10);
        User user = new User(
            FirstName = 'Kari',
            LastName = lastName,
            Email = 'contact.model.' + unique + '@example.com',
            Username = 'contact.model.' + unique + '@example.com',
            Alias = unique.substring(0, 8),
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = minimumAccessProfile.Id
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert user;
            if (permissionSetName != null) {
                PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
                insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id);
            }
        }
        return user;
    }

    /**
     * Creates an organization account.
     *
     * @param name Account name.
     * @return Inserted account.
     */
    public static Account createOrganization(String name) {
        Account organization = new Account(Name = name);
        insert organization;
        return organization;
    }

    /**
     * Creates an application for an organization with the address the applicant used there.
     *
     * @param organization Organization account.
     * @param email Address the applicant entered for the organization.
     * @return Inserted application.
     */
    public static Application__c createApplication(Account organization, String email) {
        Application__c application = new Application__c(Account__c = organization.Id, Email__c = email);
        insert application;
        return application;
    }
}
