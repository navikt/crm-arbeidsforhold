/**
 * Read-only configuration view for the Arbeidsforhold Admin app.
 *
 * Shows feature flags, P360 transport settings, trigger settings, default settings and
 * notification metadata with a one-sentence explanation and a Setup link. The view never
 * writes and never shows secret or personal values; addresses and contact references are
 * reported as present or missing only.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
public with sharing class AAREG_AdminConfigurationController {
    private static final String VALUE_ON = 'På';
    private static final String VALUE_OFF = 'Av';
    private static final String NOT_SET = 'Ikkje sett';
    private static final String VALUE_SET = 'Sett';

    /**
     * One configuration value with its explanation.
     */
    public class Item {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String explanation;

        Item(String label, String value, String state, String explanation) {
            this.label = label;
            this.value = value;
            this.state = state;
            this.explanation = explanation;
        }
    }

    /**
     * A group of configuration values that share a Setup location.
     */
    public class Section {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String setupUrl;
        @AuraEnabled
        public List<Item> items = new List<Item>();

        Section(String key, String title, String setupUrl) {
            this.key = key;
            this.title = title;
            this.setupUrl = setupUrl;
        }
    }

    /**
     * Returns the current configuration, grouped by Setup location.
     *
     * @return Sections in display order; a section that cannot be read contains an explanation item.
     * @since 2026-11
     */
    @AuraEnabled(cacheable=true)
    public static List<Section> getConfiguration() {
        return new List<Section>{ p360Section(), triggerSection(), defaultSettingsSection(), notificationSection() };
    }

    private static Section p360Section() {
        Section section = new Section('p360', 'P360-arkivering', '/lightning/setup/CustomSettings/home');
        Boolean enabled = P360_ArchiveProcessingGate.isEnabled();
        section.items.add(
            new Item(
                'P360-arkivering (feature flag)',
                enabled ? VALUE_ON : VALUE_OFF,
                enabled ? 'warning' : 'neutral',
                'Når flagget er på, blir godkjende vedtak sende til arkivering i P360.'
            )
        );

        P360_Integration_Setting__c setting = P360_Integration_Setting__c.getOrgDefaults();
        Boolean mock = setting != null && setting.Use_Mock_Transport__c == true;
        section.items.add(
            new Item(
                'Mock-transport',
                mock ? VALUE_ON : VALUE_OFF,
                mock ? 'success' : 'warning',
                'Når mock-transport er på, går ingen data til P360; svaret blir simulert i Salesforce.'
            )
        );
        section.items.add(credentialItem(setting == null ? null : setting.Named_Credential_Name__c));
        section.items.add(
            new Item(
                'RPC-klient',
                setting == null || String.isBlank(setting.Rpc_Client_Class__c) ? NOT_SET : setting.Rpc_Client_Class__c,
                'neutral',
                'Apex-klassen som byggjer og sender førespurnaden til P360.'
            )
        );
        section.items.add(
            new Item(
                'Eksternt system',
                setting == null || String.isBlank(setting.External_System__c) ? NOT_SET : setting.External_System__c,
                'neutral',
                'Systemnamnet som blir sendt med i P360-førespurnaden.'
            )
        );
        return section;
    }

    private static Item credentialItem(String credentialName) {
        String explanation = 'Named Credential som gir adresse og autentisering mot P360; berre namnet blir vist.';
        if (String.isBlank(credentialName)) {
            return new Item('Named Credential', NOT_SET, 'neutral', explanation);
        }
        Boolean present = false;
        try {
            present = ![SELECT Id FROM NamedCredential WHERE DeveloperName = :credentialName WITH USER_MODE LIMIT 1]
                .isEmpty();
        } catch (QueryException error) {
            return new Item('Named Credential', credentialName + ' (kan ikkje kontrollerast)', 'warning', explanation);
        }
        return present
            ? new Item('Named Credential', credentialName, 'success', explanation)
            : new Item('Named Credential', credentialName + ' (finst ikkje i orga)', 'warning', explanation);
    }

    private static Section triggerSection() {
        Section section = new Section(
            'triggers',
            'Triggerinnstillingar (MyTriggerSetting)',
            '/lightning/setup/CustomMetadata/home'
        );
        List<MyTriggerSetting__mdt> settings = MyTriggerSetting__mdt.getAll().values();
        List<String> labels = new List<String>();
        Map<String, MyTriggerSetting__mdt> byLabel = new Map<String, MyTriggerSetting__mdt>();
        for (MyTriggerSetting__mdt setting : settings) {
            if (!isRelevantTrigger(setting)) {
                continue;
            }
            String label = setting.sObjectAPIName__c + ' / ' + setting.Class__c + ' (' + setting.Event__c + ')';
            labels.add(label);
            byLabel.put(label, setting);
        }
        labels.sort();
        for (String label : labels) {
            Boolean active = byLabel.get(label).Active__c == true;
            section.items.add(
                new Item(
                    label,
                    active ? 'Aktiv' : 'Inaktiv',
                    active ? 'success' : 'warning',
                    'Styrer om trigger-handlaren køyrer for denne hendinga.'
                )
            );
        }
        if (section.items.isEmpty()) {
            section.items.add(
                new Item('Ingen treff', NOT_SET, 'neutral', 'Fann ingen relevante triggerinnstillingar.')
            );
        }
        return section;
    }

    private static Boolean isRelevantTrigger(MyTriggerSetting__mdt setting) {
        String text = (setting.Class__c + ' ' + setting.sObjectAPIName__c).toUpperCase();
        return text.contains('AAREG') ||
            text.contains('P360') ||
            text.contains('APPLICATION') ||
            text.contains('AGREEMENT') ||
            text.contains('INQUIRY') ||
            text.contains('ACCESS_REQUEST');
    }

    private static Section defaultSettingsSection() {
        Section section = new Section(
            'defaults',
            'Standardinnstillingar (AAREG_Default_Settings)',
            '/lightning/setup/CustomSettings/home'
        );
        AAREG_Default_Settings__c setting = AAREG_Default_Settings__c.getOrgDefaults();
        section.items.add(
            new Item(
                'Standard saksbehandlar-e-post',
                presence(setting == null ? null : setting.Default_Case_Handler_Email__c),
                'neutral',
                'Adressa som får varsel når ingen saksbehandlar er sett; sjølve adressa blir ikkje vist.'
            )
        );
        section.items.add(
            new Item(
                'Standardkontakt',
                presence(setting == null ? null : setting.Default_Contact__c),
                'neutral',
                'Kontakten som blir brukt på henvendingar utan kjend avsendar; sjølve kontakten blir ikkje vist.'
            )
        );
        return section;
    }

    private static Section notificationSection() {
        Section section = new Section(
            'notifications',
            'E-postvarsel (AAREG_email_notification)',
            '/lightning/setup/CustomMetadata/home'
        );
        List<String> names = new List<String>(AAREG_email_notification__mdt.getAll().keySet());
        names.sort();
        for (String name : names) {
            section.items.add(
                new Item(
                    name,
                    presence(AAREG_email_notification__mdt.getInstance(name).Email__c),
                    'neutral',
                    'Mottakaradresse for automatiske e-postvarsel; sjølve adressa blir ikkje vist.'
                )
            );
        }
        if (section.items.isEmpty()) {
            section.items.add(new Item('Ingen treff', NOT_SET, 'neutral', 'Fann ingen varselinnstillingar.'));
        }
        return section;
    }

    private static String presence(String value) {
        return String.isBlank(value) ? NOT_SET : VALUE_SET;
    }
}
