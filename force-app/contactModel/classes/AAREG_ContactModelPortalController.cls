/**
 * Portal endpoints for the searchable organization selector and «Min profil».
 *
 * Every Id and identity is derived on the server from the signed-in user. Organization data is only returned after
 * Altinn has confirmed the user's right for the organization in the same request, and an address is only returned
 * for the context it belongs to. There is no fallback between contexts.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactModelPortalController {
    /** Altinn resource that grants access to apply for Aa-register access. */
    public static final String ALTINN_RESOURCE = 'nav_arbeidsforhold_aa-registeret-sok-tilgang';
    private static final Pattern EMAIL_PATTERN = Pattern.compile('^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');

    private static final Pattern ORGANIZATION_NUMBER_PATTERN = Pattern.compile('^\\d{9}$');
    private static final Registry REGISTRY = new Registry();

    @TestVisible
    private static AltinnCalloutService altinnOverride;

    /**
     * Which portal features are on for the signed-in user.
     */
    public class Settings {
        /** Role first and searchable organization selector. */
        @AuraEnabled
        public Boolean orgSelector;
        /** «Min profil». */
        @AuraEnabled
        public Boolean profile;
        /** Notifications use the address for the current context. */
        @AuraEnabled
        public Boolean contextAddress;
    }

    /**
     * One organization the user can choose.
     */
    public class OrganizationOption {
        /** Organization number. */
        @AuraEnabled
        public String organizationNumber;
        /** Name. */
        @AuraEnabled
        public String name;
        /** Unit type from Altinn, for example AS or BEDR. */
        @AuraEnabled
        public String unitType;
        /** Name of the parent unit for subunits. */
        @AuraEnabled
        public String parentName;
    }

    /**
     * Profile content for «Min profil».
     */
    public class Profile {
        /** Name of the signed-in user. */
        @AuraEnabled
        public String name;
        /** Private address, entered by the person. */
        @AuraEnabled
        public String privateEmail;
        /** Private phone. */
        @AuraEnabled
        public String privatePhone;
        /** The selected organization, only present after Altinn verification. */
        @AuraEnabled
        public OrganizationContext organization;
    }

    /**
     * Address for one verified organization.
     */
    public class OrganizationContext {
        /** Organization number. */
        @AuraEnabled
        public String organizationNumber;
        /** Organization name. */
        @AuraEnabled
        public String name;
        /** Whether Altinn confirmed the right in this request. */
        @AuraEnabled
        public Boolean verified = false;
        /** Address for this organization. Null when missing; never another context's address. */
        @AuraEnabled
        public String email;
        /** Phone for this organization. */
        @AuraEnabled
        public String phone;
        /** Explanation when the organization is not verified or unknown. */
        @AuraEnabled
        public String message;
    }

    /**
     * Returns which features are on. The profile and the role-first start are off for shielded persons (ADR-0008).
     *
     * @return Feature switches for the signed-in user.
     */
    @AuraEnabled
    public static Settings getSettings() {
        Settings settings = new Settings();
        Boolean shielded = AAREG_ContactModelShielding.isShieldedUser(UserInfo.getUserId());
        settings.orgSelector = AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.ORG_SELECTOR) && !shielded;
        settings.profile = AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.PROFILE) && !shielded;
        settings.contextAddress = AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.CONTEXT_ADDRESS);
        return settings;
    }

    /**
     * Returns the organizations Altinn reports for the signed-in user, including subunits, sorted by name.
     *
     * @return Organizations the user can choose.
     * @throws AuraHandledException When the selector is off, the person is shielded, or Altinn cannot be reached.
     */
    @AuraEnabled
    public static List<OrganizationOption> getOrganizations() {
        requireUnshieldedFlag(AAREG_ContactModelGate.ORG_SELECTOR);
        String personIdent = personIdent();
        AltinnCalloutService.AltinnOrganizationsResponse response;
        try {
            response = altinn(personIdent).getOrganizations(personIdent);
        } catch (Exception error) {
            throw auraError('Kunne ikkje hente organisasjonar frå Altinn. Prøv igjen seinare.');
        }
        if (response == null || response.success != true) {
            throw auraError('Kunne ikkje hente organisasjonar frå Altinn. Prøv igjen seinare.');
        }
        List<OrganizationOption> options = new List<OrganizationOption>();
        Set<String> seen = new Set<String>();
        for (
            AltinnCalloutService.Organization organization : response.organizations ??
                new List<AltinnCalloutService.Organization>()
        ) {
            addOption(options, seen, organization, null);
            for (
                AltinnCalloutService.Organization subunit : organization.subunits ??
                    new List<AltinnCalloutService.Organization>()
            ) {
                addOption(options, seen, subunit, organization.name);
            }
        }
        return sortByName(options);
    }

    /**
     * Returns the profile. Organization data is only included when Altinn confirms the right in this request.
     *
     * @param organizationNumber Selected organization, or blank for «Meg selv» only.
     * @return Profile with the private address and, when verified, the address for the selected organization.
     * @throws AuraHandledException When the profile is off or the person is shielded.
     */
    @AuraEnabled
    public static Profile getProfile(String organizationNumber) {
        requireProfile();
        Contact contact = AAREG_ContactModelService.findContactForUser(UserInfo.getUserId());
        Profile profile = new Profile();
        profile.name = UserInfo.getName();
        AAREG_Contact_Point__c privatePoint = AAREG_ContactModelService.findContactPoint(contact?.Id, null);
        profile.privateEmail = privatePoint?.Email__c;
        profile.privatePhone = privatePoint?.Phone__c;
        if (String.isNotBlank(organizationNumber)) {
            profile.organization = organizationContext(contact, organizationNumber);
        }
        return profile;
    }

    /**
     * Saves the address for «Meg selv» or for a verified organization. Other contexts are not changed.
     *
     * @param organizationNumber Organization, or blank for the private context.
     * @param email Address. Required.
     * @param phone Phone. Optional.
     * @return Updated profile for the same context.
     * @throws AuraHandledException When the profile is off, the person is shielded, the address is invalid, or Altinn
     * denies the right.
     */
    @AuraEnabled
    public static Profile saveAddress(String organizationNumber, String email, String phone) {
        requireProfile();
        if (String.isBlank(email) || !EMAIL_PATTERN.matcher(email.trim()).matches()) {
            throw auraError('Skriv inn ei gyldig e-postadresse.');
        }
        Id organizationId = null;
        if (String.isNotBlank(organizationNumber)) {
            if (!hasAltinnRight(organizationNumber)) {
                throw auraError('Altinn stadfestar ikkje at du har rolla for denne organisasjonen.');
            }
            organizationId = accountId(organizationNumber);
            if (organizationId == null) {
                throw auraError('Organisasjonen finst ikkje i Aa-registeret enno.');
            }
        }
        Contact contact;
        try {
            contact = AAREG_ContactModelService.ensureContactForUser(UserInfo.getUserId());
            AAREG_ContactModelService.saveContactPoint(contact.Id, organizationId, email, phone);
            if (organizationId != null) {
                markVerified(contact.Id, organizationId);
            }
        } catch (AAREG_ContactModelService.ContactModelException error) {
            throw auraError('Profilen kan ikkje lagrast no. Kontakt brukarstøtte.');
        }
        // Built without a new Altinn call: a callout after the DML above is not allowed in the same transaction.
        Profile profile = new Profile();
        profile.name = UserInfo.getName();
        AAREG_Contact_Point__c privatePoint = AAREG_ContactModelService.findContactPoint(contact.Id, null);
        profile.privateEmail = privatePoint?.Email__c;
        profile.privatePhone = privatePoint?.Phone__c;
        if (organizationId != null) {
            OrganizationContext context = new OrganizationContext();
            context.organizationNumber = organizationNumber;
            context.verified = true;
            context.name = REGISTRY.organizationName(organizationId);
            AAREG_Contact_Point__c point = AAREG_ContactModelService.findContactPoint(contact.Id, organizationId);
            context.email = point?.Email__c;
            context.phone = point?.Phone__c;
            profile.organization = context;
        }
        return profile;
    }

    /**
     * Selects the organization for a new application after the user has chosen a role. Altinn must confirm the right
     * to apply in this request; the existing «last used organization» on the user is then set, so the application form
     * loads that organization as before.
     *
     * @param organizationNumber Organization chosen in the selector.
     * @return The selected organization number.
     * @throws AuraHandledException When the selector is off, the person is shielded, Altinn denies the right, or the
     *         organization is unknown.
     */
    @AuraEnabled
    public static String selectApplicationOrganization(String organizationNumber) {
        requireUnshieldedFlag(AAREG_ContactModelGate.ORG_SELECTOR);
        String normalized = (organizationNumber ?? '').deleteWhitespace();
        if (!ORGANIZATION_NUMBER_PATTERN.matcher(normalized).matches()) {
            throw auraError('Vel ein organisasjon frå lista.');
        }
        if (!hasAltinnRight(normalized)) {
            throw auraError(
                'Altinn stadfestar ikkje at du kan søkje på vegner av denne organisasjonen. Sjekk rolla di i Altinn.'
            );
        }
        if (accountId(normalized) == null) {
            throw auraError('Organisasjonen finst ikkje i Aa-registeret enno. Vel organisasjonen på forsida først.');
        }
        REGISTRY.rememberOrganization(UserInfo.getUserId(), normalized);
        return normalized;
    }

    private static OrganizationContext organizationContext(Contact contact, String organizationNumber) {
        OrganizationContext context = new OrganizationContext();
        context.organizationNumber = organizationNumber;
        if (!hasAltinnRight(organizationNumber)) {
            context.message = 'Altinn stadfestar ikkje rolla di for denne organisasjonen. Vel ein annan organisasjon eller sjekk rolla i Altinn.';
            return context;
        }
        context.verified = true;
        Id organizationId = accountId(organizationNumber);
        if (organizationId == null) {
            context.message = 'Organisasjonen finst ikkje i Aa-registeret enno. Adressa blir lagra når du sender ein søknad.';
            return context;
        }
        context.name = REGISTRY.organizationName(organizationId);
        AAREG_Contact_Point__c point = AAREG_ContactModelService.findContactPoint(contact?.Id, organizationId);
        context.email = point?.Email__c;
        context.phone = point?.Phone__c;
        if (contact != null) {
            markVerified(contact.Id, organizationId);
        }
        return context;
    }

    private static void markVerified(Id contactId, Id organizationId) {
        REGISTRY.markVerified(contactId, organizationId);
    }

    private static Boolean hasAltinnRight(String organizationNumber) {
        String personIdent = personIdent();
        try {
            AltinnCalloutService.AltinnRightsResponse response = altinn(personIdent)
                .getRights(personIdent, organizationNumber, ALTINN_RESOURCE);
            if (response == null || response.success != true || response.rights == null) {
                return false;
            }
            for (AltinnCalloutService.Right right : response.rights) {
                if (right.Action == 'Access' && right.Decision == 'Permit') {
                    return true;
                }
            }
        } catch (Exception error) {
            return false;
        }
        return false;
    }

    private static Id accountId(String organizationNumber) {
        return REGISTRY.organizationId(organizationNumber);
    }

    /**
     * Organization lookups after Altinn has confirmed the role. Portal users cannot see organization accounts or their
     * relations through sharing, so these reads and the verification stamp run without sharing. Callers must check the
     * Altinn right first.
     */
    private without sharing class Registry {
        private Id organizationId(String organizationNumber) {
            List<Account> accounts = [
                SELECT Id
                FROM Account
                WHERE INT_OrganizationNumber__c = :organizationNumber
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            return accounts.isEmpty() ? null : accounts[0].Id;
        }

        private String organizationName(Id organizationId) {
            return [SELECT Name FROM Account WHERE Id = :organizationId WITH SYSTEM_MODE].Name;
        }

        private void rememberOrganization(Id userId, String organizationNumber) {
            update as system new User(Id = userId, LastUsedOrganization__c = organizationNumber);
        }

        private void markVerified(Id contactId, Id organizationId) {
            List<AccountContactRelation> relations = [
                SELECT Id
                FROM AccountContactRelation
                WHERE ContactId = :contactId AND AccountId = :organizationId AND AAREG_Managed__c = TRUE
                WITH SYSTEM_MODE
            ];
            for (AccountContactRelation relation : relations) {
                relation.AAREG_Altinn_Verified_At__c = System.now();
            }
            update as system relations;
        }
    }

    private static String personIdent() {
        List<User> users = [
            SELECT Contact.Account.INT_PersonIdent__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SYSTEM_MODE
        ];
        return users.isEmpty() ? null : users[0].Contact?.Account?.INT_PersonIdent__c;
    }

    private static AltinnCalloutService altinn(String personIdent) {
        if (altinnOverride != null) {
            return altinnOverride;
        }
        return AAREG_AltinnServiceFactory.createService(UserInfo.getUserId(), personIdent);
    }

    private static void addOption(
        List<OrganizationOption> options,
        Set<String> seen,
        AltinnCalloutService.Organization organization,
        String parentName
    ) {
        if (
            organization == null ||
            String.isBlank(organization.organizationNumber) ||
            organization.isDeleted == 'true' ||
            seen.contains(organization.organizationNumber)
        ) {
            return;
        }
        seen.add(organization.organizationNumber);
        OrganizationOption option = new OrganizationOption();
        option.organizationNumber = organization.organizationNumber;
        option.name = organization.name;
        option.unitType = organization.unitType;
        option.parentName = parentName;
        options.add(option);
    }

    private static List<OrganizationOption> sortByName(List<OrganizationOption> options) {
        Map<String, OrganizationOption> byKey = new Map<String, OrganizationOption>();
        for (OrganizationOption option : options) {
            byKey.put((option.name ?? '').toLowerCase() + '|' + option.organizationNumber, option);
        }
        List<String> keys = new List<String>(byKey.keySet());
        keys.sort();
        List<OrganizationOption> sorted = new List<OrganizationOption>();
        for (String key : keys) {
            sorted.add(byKey.get(key));
        }
        return sorted;
    }

    private static void requireProfile() {
        requireUnshieldedFlag(AAREG_ContactModelGate.PROFILE);
    }

    private static void requireUnshieldedFlag(String flagName) {
        requireFlag(flagName);
        if (AAREG_ContactModelShielding.isShieldedUser(UserInfo.getUserId())) {
            throw auraError('Funksjonen er ikkje tilgjengeleg for deg.');
        }
    }

    private static void requireFlag(String flagName) {
        if (!AAREG_ContactModelGate.isEnabled(flagName)) {
            throw auraError('Funksjonen er ikkje slått på.');
        }
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
