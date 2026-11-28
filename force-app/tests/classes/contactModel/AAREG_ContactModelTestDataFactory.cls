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
     * Assigns a permission set to the running user. Call System.runAs(new User(Id = UserInfo.getUserId())) afterwards
     * so the new permissions apply. Does nothing when the running user already has the permission set.
     *
     * @param permissionSetName Permission set to assign.
     */
    public static void assignToCurrentUser(String permissionSetName) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
        Boolean assigned = ![
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSet.Id
                LIMIT 1
            ]
            .isEmpty();
        if (assigned) {
            return;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSet.Id);
        }
    }

    /**
     * Creates an organization account.
     *
     * @param name Account name.
     * @return Inserted account.
     */
    public static Account createOrganization(String name) {
        Account organization = new Account(Name = name);
        insert as system organization;
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
        insert as system application;
        return application;
    }

    private static Id portalAccountOwnerId;

    /**
     * Creates a portal user with its own person contact, like an ID-porten login.
     *
     * @param lastName Last name, also used in the account name.
     * @param personIdent Synthetic person identifier stored on the account.
     * @return Inserted portal user.
     */
    public static User createPortalUser(String lastName, String personIdent) {
        Id administratorId = UserInfo.getUserId();
        Account account = new Account(
            Name = 'Portal ' + lastName,
            INT_PersonIdent__c = personIdent,
            OwnerId = portalAccountOwner()
        );
        insert as system account;
        Contact contact = new Contact(FirstName = 'Kari', LastName = lastName, AccountId = account.Id);
        insert as system contact;

        Profile communityProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType IN ('PowerCustomerSuccess', 'CustomerSuccess', 'CSPLitePortal')
            ORDER BY UserType DESC
            LIMIT 1
        ];
        String unique = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 10);
        User user = new User(
            FirstName = 'Kari',
            LastName = lastName,
            Email = 'portal.' + unique + '@example.com',
            Username = 'portal.' + unique + '@example.com',
            Alias = unique.substring(0, 8),
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = communityProfile.Id,
            ContactId = contact.Id
        );
        System.runAs(new User(Id = administratorId)) {
            insert as system user;
        }
        return user;
    }

    /**
     * Creates an application submitted by a portal user, so CreatedBy.ContactId is set.
     *
     * @param portalUser Portal user who creates the application.
     * @param organization Organization account.
     * @param email Address the applicant entered for the organization.
     * @return Inserted application with Casehandler_Status__c set and the organization linked.
     */
    public static Application__c createSubmittedApplication(User portalUser, Account organization, String email) {
        Application__c application = new Application__c(Email__c = email, Casehandler_Status__c = 'New');
        System.runAs(portalUser) {
            insert as system application;
        }
        // Portal users cannot reference organization accounts they do not share; the organization is linked afterwards.
        application.Account__c = organization.Id;
        update as system application;
        return application;
    }

    /**
     * Marks a portal user's person as shielded (strictly confidential address).
     *
     * @param portalUser Portal user created by createPortalUser.
     */
    public static void shieldPerson(User portalUser) {
        Person__c person = new Person__c(
            Name = ('20088' + String.valueOf(Crypto.getRandomInteger()).remove('-') + '000000').left(11),
            INT_Confidential__c = 'STRENGT_FORTROLIG',
            INT_IsDeceased__c = false
        );
        insert as system person;
        Id accountId = [SELECT Contact.AccountId FROM User WHERE Id = :portalUser.Id WITH SYSTEM_MODE]
        .Contact.AccountId;
        update as system new Account(Id = accountId, CRM_Person__c = person.Id);
    }

    private static Id portalAccountOwner() {
        if (portalAccountOwnerId != null) {
            return portalAccountOwnerId;
        }
        String unique = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 10);
        UserRole role = new UserRole(
            Name = 'Contact Model Test ' + unique,
            DeveloperName = 'Contact_Model_Test_' + unique
        );
        Profile internalProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User owner = new User(
            FirstName = 'Portal',
            LastName = 'Owner',
            Email = 'portal.owner.' + unique + '@example.com',
            Username = 'portal.owner.' + unique + '@example.com',
            Alias = 'own' + unique.substring(0, 5),
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = internalProfile.Id
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert as system role;
            owner.UserRoleId = role.Id;
            insert as system owner;
        }
        portalAccountOwnerId = owner.Id;
        return owner.Id;
    }
}
