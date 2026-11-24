/**
 * Read-only contact model panel for Contact, Account and Application record pages.
 *
 * Runs in user mode, so sharing and field-level security decide what is shown. Addresses are only returned when the
 * user can read AAREG_Contact_Point__c.Email__c, which AAREG_ContactModel_Admin grants.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactModelPanelController {
    private static final Integer ROW_LIMIT = 200;
    private static final String HIDDEN = 'Skjult';

    /**
     * Panel content.
     */
    public class Panel {
        /** What the record is in the contact model. */
        @AuraEnabled
        public String summary;
        /** Sections in display order. */
        @AuraEnabled
        public List<Section> sections = new List<Section>();
    }

    /**
     * One table in the panel.
     */
    public class Section {
        /** Stable key. */
        @AuraEnabled
        public String key;
        /** Heading. */
        @AuraEnabled
        public String title;
        /** Column definitions for lightning-datatable. */
        @AuraEnabled
        public List<Map<String, Object>> columns = new List<Map<String, Object>>();
        /** Rows keyed by column field name. */
        @AuraEnabled
        public List<Map<String, Object>> rows = new List<Map<String, Object>>();
        /** Text shown when there are no rows. */
        @AuraEnabled
        public String emptyText;

        Section(String key, String title, String emptyText) {
            this.key = key;
            this.title = title;
            this.emptyText = emptyText;
        }

        Section text(String fieldName, String label) {
            columns.add(new Map<String, Object>{ 'label' => label, 'fieldName' => fieldName, 'type' => 'text' });
            return this;
        }

        Section link(String fieldName, String label, String labelField) {
            columns.add(
                new Map<String, Object>{
                    'label' => label,
                    'fieldName' => fieldName,
                    'type' => 'url',
                    'typeAttributes' => new Map<String, Object>{
                        'label' => new Map<String, Object>{ 'fieldName' => labelField },
                        'target' => '_self'
                    }
                }
            );
            return this;
        }
    }

    /**
     * Returns the panel for a record.
     *
     * @param recordId Contact, Account or Application__c Id.
     * @return Panel content; a summary only when the record type is not supported.
     */
    @AuraEnabled(cacheable=true)
    public static Panel getPanel(Id recordId) {
        Panel panel = new Panel();
        if (recordId == null) {
            panel.summary = 'Ingen post.';
            return panel;
        }
        SObjectType type = recordId.getSobjectType();
        if (type == Contact.SObjectType) {
            return contactPanel(recordId);
        }
        if (type == Account.SObjectType) {
            return accountPanel(recordId);
        }
        if (type == Application__c.SObjectType) {
            return applicationPanel(recordId);
        }
        panel.summary = 'Kontaktmodellen har ingen visning for denne posttypen.';
        return panel;
    }

    private static Panel contactPanel(Id contactId) {
        Panel panel = new Panel();
        List<Contact> contacts = [SELECT Id, AAREG_Identity_Key__c FROM Contact WHERE Id = :contactId WITH USER_MODE];
        Boolean isDomainContact = !contacts.isEmpty() && String.isNotBlank(contacts[0].AAREG_Identity_Key__c);
        panel.summary = isDomainContact
            ? 'Domenekontakt i Aa-registeret. Organisasjonar, adresser og roller står under.'
            : 'Dette er ikkje ein domenekontakt. Han kan vere ein eldre kontakt per e-postadresse.';

        Section organizations = new Section('organizations', 'Organisasjonar (ACR)', 'Ingen organisasjonstilknytingar.')
            .link('accountUrl', 'Organisasjon', 'accountName')
            .text('organizationNumber', 'Org.nr.')
            .text('managed', 'Forvalta av kontaktmodellen')
            .text('verifiedAt', 'Sist kontrollert i Altinn');
        for (AccountContactRelation relation : [
            SELECT
                AccountId,
                Account.Name,
                Account.INT_OrganizationNumber__c,
                AAREG_Managed__c,
                AAREG_Altinn_Verified_At__c,
                IsDirect
            FROM AccountContactRelation
            WHERE ContactId = :contactId AND IsDirect = FALSE
            WITH USER_MODE
            ORDER BY Account.Name
            LIMIT :ROW_LIMIT
        ]) {
            organizations.rows.add(
                new Map<String, Object>{
                    'id' => relation.AccountId,
                    'accountUrl' => '/' + relation.AccountId,
                    'accountName' => relation.Account.Name,
                    'organizationNumber' => relation.Account.INT_OrganizationNumber__c,
                    'managed' => relation.AAREG_Managed__c == true ? 'Ja' : 'Nei',
                    'verifiedAt' => relation.AAREG_Altinn_Verified_At__c?.format()
                }
            );
        }
        panel.sections.add(organizations);
        panel.sections.add(contactPointSection(contactPointsFor(contactId, null), true));
        panel.sections.add(participationSection(participations('Contact__c', contactId, 'CreatedDate DESC'), true));
        return panel;
    }

    private static Panel accountPanel(Id accountId) {
        Panel panel = new Panel();
        Section people = new Section(
                'people',
                'Personar med tilknyting (ACR)',
                'Ingen personar er kopla til organisasjonen.'
            )
            .link('contactUrl', 'Person', 'contactName')
            .text('managed', 'Forvalta av kontaktmodellen')
            .text('verifiedAt', 'Sist kontrollert i Altinn');
        for (AccountContactRelation relation : [
            SELECT ContactId, Contact.Name, AAREG_Managed__c, AAREG_Altinn_Verified_At__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId AND IsDirect = FALSE
            WITH USER_MODE
            ORDER BY Contact.Name
            LIMIT :ROW_LIMIT
        ]) {
            people.rows.add(
                new Map<String, Object>{
                    'id' => relation.ContactId,
                    'contactUrl' => '/' + relation.ContactId,
                    'contactName' => relation.Contact.Name,
                    'managed' => relation.AAREG_Managed__c == true ? 'Ja' : 'Nei',
                    'verifiedAt' => relation.AAREG_Altinn_Verified_At__c?.format()
                }
            );
        }
        panel.summary = people.rows.size() + ' personar er kopla til organisasjonen.';
        panel.sections.add(people);
        panel.sections.add(contactPointSection(contactPointsFor(null, accountId), false));
        return panel;
    }

    private static Panel applicationPanel(Id applicationId) {
        Panel panel = new Panel();
        List<RelatedContact__c> participations = participations('Application__c', applicationId, 'Role__c');
        Integer linked = 0;
        for (RelatedContact__c participation : participations) {
            if (participation.Contact__c != null) {
                linked++;
            }
        }
        panel.summary = linked + ' av ' + participations.size() + ' deltakingar er kopla til ein domenekontakt.';
        panel.sections.add(participationSection(participations, false));
        return panel;
    }

    private static List<AAREG_Contact_Point__c> contactPointsFor(Id contactId, Id organizationId) {
        if (!Schema.SObjectType.AAREG_Contact_Point__c.isAccessible()) {
            return new List<AAREG_Contact_Point__c>();
        }
        String query =
            'SELECT Id, Name, Context__c, Contact__c, Contact__r.Name, Organization__c, Organization__r.Name' +
            (canReadAddresses() ? ', Email__c, Phone__c' : '') +
            ' FROM AAREG_Contact_Point__c WHERE ' +
            (contactId != null ? 'Contact__c = :contactId' : 'Organization__c = :organizationId') +
            ' ORDER BY Context__c DESC, Organization__r.Name LIMIT ' +
            ROW_LIMIT;
        return Database.queryWithBinds(
            query,
            new Map<String, Object>{ 'contactId' => contactId, 'organizationId' => organizationId },
            AccessLevel.USER_MODE
        );
    }

    private static Section contactPointSection(List<AAREG_Contact_Point__c> points, Boolean byOrganization) {
        Section section = new Section(
            'contactPoints',
            'Kontaktpunkt (adresser per kontekst)',
            Schema.SObjectType.AAREG_Contact_Point__c.isAccessible()
                ? 'Ingen kontaktpunkt.'
                : 'Du har ikkje tilgang til kontaktpunkt. Adresser blir viste for administratorar.'
        );
        section.link('pointUrl', 'Kontaktpunkt', 'pointName').text('context', 'Kontekst');
        if (byOrganization) {
            section.text('organizationName', 'Organisasjon');
        } else {
            section.link('contactUrl', 'Person', 'contactName');
        }
        section.text('email', 'E-post').text('phone', 'Telefon');
        Boolean readable = canReadAddresses();
        for (AAREG_Contact_Point__c point : points) {
            section.rows.add(
                new Map<String, Object>{
                    'id' => point.Id,
                    'pointUrl' => '/' + point.Id,
                    'pointName' => point.Name,
                    'context' => point.Context__c == AAREG_ContactModelService.CONTEXT_PRIVATE
                        ? 'Privat'
                        : 'Organisasjon',
                    'organizationName' => point.Organization__r?.Name,
                    'contactUrl' => '/' + point.Contact__c,
                    'contactName' => point.Contact__r?.Name,
                    'email' => readable ? point.Email__c : HIDDEN,
                    'phone' => readable ? point.Phone__c : HIDDEN
                }
            );
        }
        return section;
    }

    private static Section participationSection(List<RelatedContact__c> participations, Boolean byApplication) {
        Section section = new Section('participations', 'Roller på søknader', 'Ingen roller.');
        if (byApplication) {
            section.link('applicationUrl', 'Søknad', 'applicationName').text('status', 'Status');
        } else {
            section.link('contactUrl', 'Domenekontakt', 'contactName');
        }
        section.text('role', 'Rolle').text('linked', 'Kontaktpunkt kopla');
        for (RelatedContact__c participation : participations) {
            section.rows.add(
                new Map<String, Object>{
                    'id' => participation.Id,
                    'applicationUrl' => '/' + participation.Application__c,
                    'applicationName' => participation.Application__r?.Name,
                    'status' => participation.Application__r?.Casehandler_Status__c,
                    'contactUrl' => participation.Contact__c == null ? null : '/' + participation.Contact__c,
                    'contactName' => participation.Contact__c == null
                        ? participation.Name + ' (ikkje kopla)'
                        : participation.Contact__r.Name,
                    'role' => participation.Role__c,
                    'linked' => !canReadContactPoints() ? HIDDEN : participation.Contact_Point__c == null ? 'Nei' : 'Ja'
                }
            );
        }
        return section;
    }

    // The contact point lookup is only queryable when the user can read the contact point object.
    private static List<RelatedContact__c> participations(String filterField, Id recordId, String orderBy) {
        String query =
            'SELECT Id, Name, Role__c, Application__c, Application__r.Name, Application__r.Casehandler_Status__c,' +
            ' Contact__c, Contact__r.Name' +
            (canReadContactPoints() ? ', Contact_Point__c' : '') +
            ' FROM RelatedContact__c WHERE ' +
            filterField +
            ' = :recordId ORDER BY ' +
            orderBy +
            ' LIMIT ' +
            ROW_LIMIT;
        return Database.queryWithBinds(query, new Map<String, Object>{ 'recordId' => recordId }, AccessLevel.USER_MODE);
    }

    private static Boolean canReadContactPoints() {
        return Schema.SObjectType.AAREG_Contact_Point__c.isAccessible();
    }

    private static Boolean canReadAddresses() {
        return Schema.SObjectType.AAREG_Contact_Point__c.fields.Email__c.isAccessible();
    }
}
