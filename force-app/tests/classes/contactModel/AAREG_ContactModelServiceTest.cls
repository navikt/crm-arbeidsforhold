/**
 * Tests shadow writing of the Aa-register contact model.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelServiceTest {
    @IsTest
    static void firstSubmissionCreatesContactRelationAndSubmitterParticipation() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Nordmann', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Bedrift AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'kari@bedrift.example'
        );

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });
        System.Test.stopTest();

        Contact contact = getDomainContact(submitter.Id);
        System.Assert.areEqual('Nordmann', contact.LastName, 'Name comes from the portal user');
        System.Assert.areEqual(AAREG_ContactModelService.getPrimaryAccountId(), contact.AccountId, 'Primary account');

        AccountContactRelation relation = getRelation(organization.Id, contact.Id);
        System.Assert.isTrue(relation.AAREG_Managed__c, 'Relation is managed by Aa-registeret');

        AAREG_Contact_Point__c point = getContactPoint(contact.Id, organization.Id);
        System.Assert.areEqual('kari@bedrift.example', point.Email__c, 'Address at the organization');
        System.Assert.areEqual(
            AAREG_ContactModelService.CONTEXT_ORGANIZATION,
            point.Context__c,
            'Organization context'
        );
        System.Assert.areEqual(
            0,
            [
                SELECT COUNT()
                FROM AAREG_Contact_Point__c
                WHERE Contact__c = :contact.Id AND Organization__c = NULL
                WITH SYSTEM_MODE
            ],
            'Organization address is never used as private address'
        );

        RelatedContact__c participation = [
            SELECT Role__c, Contact__c, Email__c, Contact_Point__c
            FROM RelatedContact__c
            WHERE Application__c = :application.Id
            WITH SYSTEM_MODE
        ];
        System.Assert.areEqual('Submitter', participation.Role__c, 'Submitter role');
        System.Assert.areEqual(contact.Id, participation.Contact__c, 'Linked to the domain contact');
        System.Assert.areEqual(point.Id, participation.Contact_Point__c, 'Linked to the contact point');
        System.Assert.areEqual('kari@bedrift.example', participation.Email__c, 'Address at submission');
    }

    @IsTest
    static void resubmissionReusesContactWithoutDuplicates() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Igjen', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Igjen AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'a@igjen.example'
        );
        Map<Id, Id> submission = new Map<Id, Id>{ application.Id => submitter.Id };

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(submission);
        AAREG_ContactModelService.recordSubmissions(submission);
        System.Test.stopTest();

        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c = :submitter.Id WITH SYSTEM_MODE],
            'One contact'
        );
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM AccountContactRelation WHERE AccountId = :organization.Id WITH SYSTEM_MODE],
            'One relation'
        );
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM RelatedContact__c WHERE Application__c = :application.Id WITH SYSTEM_MODE],
            'One participation'
        );
    }

    @IsTest
    static void eachOrganizationKeepsItsOwnAddress() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Fleire', null);
        Account first = AAREG_ContactModelTestDataFactory.createOrganization('Første AS');
        Account second = AAREG_ContactModelTestDataFactory.createOrganization('Andre AS');
        Application__c firstApplication = AAREG_ContactModelTestDataFactory.createApplication(
            first,
            'kari@forste.example'
        );
        Application__c secondApplication = AAREG_ContactModelTestDataFactory.createApplication(
            second,
            'kari@andre.example'
        );

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(
            new Map<Id, Id>{ firstApplication.Id => submitter.Id, secondApplication.Id => submitter.Id }
        );
        System.Test.stopTest();

        Contact contact = getDomainContact(submitter.Id);
        System.Assert.areEqual('kari@forste.example', getContactPoint(contact.Id, first.Id).Email__c, 'First address');
        System.Assert.areEqual('kari@andre.example', getContactPoint(contact.Id, second.Id).Email__c, 'Second address');
    }

    @IsTest
    static void unmanagedRelationIsNotTakenOver() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Annan', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Delt AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'ny@delt.example'
        );
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });
        Contact contact = getDomainContact(submitter.Id);
        AccountContactRelation relation = getRelation(organization.Id, contact.Id);
        relation.AAREG_Managed__c = false;
        update as system relation;

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });
        System.Test.stopTest();

        System.Assert.isFalse(
            getRelation(organization.Id, contact.Id).AAREG_Managed__c,
            'Relations owned by others are left unchanged'
        );
    }

    @IsTest
    static void changedAddressKeepsOtherOrganizationAndHistory() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Endring', null);
        Account first = AAREG_ContactModelTestDataFactory.createOrganization('Endring AS');
        Account second = AAREG_ContactModelTestDataFactory.createOrganization('Uendra AS');
        Application__c firstOld = AAREG_ContactModelTestDataFactory.createApplication(first, 'gammal@endring.example');
        Application__c other = AAREG_ContactModelTestDataFactory.createApplication(second, 'fast@uendra.example');
        AAREG_ContactModelService.recordSubmissions(
            new Map<Id, Id>{ firstOld.Id => submitter.Id, other.Id => submitter.Id }
        );
        Application__c firstNew = AAREG_ContactModelTestDataFactory.createApplication(first, 'ny@endring.example');

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ firstNew.Id => submitter.Id });
        System.Test.stopTest();

        Contact contact = getDomainContact(submitter.Id);
        System.Assert.areEqual('ny@endring.example', getContactPoint(contact.Id, first.Id).Email__c, 'Latest address');
        System.Assert.areEqual(
            'fast@uendra.example',
            getContactPoint(contact.Id, second.Id).Email__c,
            'Other organization'
        );
        System.Assert.areEqual(
            'gammal@endring.example',
            [SELECT Email__c FROM RelatedContact__c WHERE Application__c = :firstOld.Id WITH SYSTEM_MODE].Email__c,
            'Submitted history keeps its snapshot'
        );
    }

    @IsTest
    static void missingPrimaryAccountThrows() {
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Utan', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Utan AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'a@utan.example'
        );

        try {
            AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });
            System.Assert.fail('Expected an exception without primary account');
        } catch (AAREG_ContactModelService.ContactModelException error) {
            System.Assert.isTrue(error.getMessage().contains('primary account'), 'Explains the missing setup');
        }
    }

    @IsTest
    static void shadowWriteRunsOnlyWhenFlagIsOn() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Flagg', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Flagg AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'a@flagg.example'
        );

        Boolean enqueuedWhenOff;
        Boolean enqueuedWhenOn;
        System.Test.startTest();
        System.runAs(submitter) {
            AAREG_ContactModelTestDataFactory.setShadowWrite(false);
            enqueuedWhenOff = AAREG_ContactModelShadowWriteJob.enqueueForCurrentUser(application.Id);
            AAREG_ContactModelTestDataFactory.setShadowWrite(true);
            enqueuedWhenOn = AAREG_ContactModelShadowWriteJob.enqueueForCurrentUser(application.Id);
        }
        System.Test.stopTest();

        System.Assert.isFalse(enqueuedWhenOff, 'Nothing is enqueued when the flag is off');
        System.Assert.isTrue(enqueuedWhenOn, 'The job is enqueued when the flag is on');
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c = :submitter.Id WITH SYSTEM_MODE],
            'Written'
        );
    }

    @IsTest
    static void shadowWriteFailureDoesNotThrow() {
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Feil', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Feil AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'a@feil.example'
        );

        System.Test.startTest();
        System.runAs(submitter) {
            AAREG_ContactModelTestDataFactory.setShadowWrite(true);
            AAREG_ContactModelShadowWriteJob.enqueueForCurrentUser(application.Id);
        }
        System.Test.stopTest();

        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM Contact WHERE AAREG_Identity_Key__c = :submitter.Id WITH SYSTEM_MODE],
            'Not written'
        );
    }

    @IsTest
    static void legacyContactListsExcludeSubmitter() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Liste', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Liste AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'a@liste.example'
        );
        insert as system new RelatedContact__c(
            Name = 'Varsel Person',
            Application__c = application.Id,
            Email__c = 'v@liste.example'
        );
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });

        List<RelatedContact__c> legacyList = [
            SELECT Id
            FROM RelatedContact__c
            WHERE Application__c = :application.Id AND Role__c != 'Submitter'
            WITH SYSTEM_MODE
        ];

        System.Assert.areEqual(1, legacyList.size(), 'Legacy rows without role remain, submitter rows are excluded');
    }

    private static Contact getDomainContact(Id userId) {
        String identityKey = userId;
        return [
            SELECT Id, LastName, AccountId
            FROM Contact
            WHERE AAREG_Identity_Key__c = :identityKey
            WITH SYSTEM_MODE
        ];
    }

    private static AccountContactRelation getRelation(Id accountId, Id contactId) {
        return [
            SELECT Id, AAREG_Managed__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId AND ContactId = :contactId
            WITH SYSTEM_MODE
        ];
    }

    private static AAREG_Contact_Point__c getContactPoint(Id contactId, Id organizationId) {
        String key = AAREG_ContactModelService.contextKey(contactId, organizationId);
        return [
            SELECT Id, Email__c, Context__c
            FROM AAREG_Contact_Point__c
            WHERE Context_Key__c = :key
            WITH SYSTEM_MODE
        ];
    }
}
