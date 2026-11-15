import { LightningElement } from 'lwc';
import getConfiguration from '@salesforce/apex/AAREG_AdminConfigurationController.getConfiguration';

const STATE_CLASS = {
    warning: 'slds-badge slds-theme_warning',
    success: 'slds-badge slds-theme_success',
    neutral: 'slds-badge'
};

export default class AaregAdminConfiguration extends LightningElement {
    sections = [];
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            const sections = await getConfiguration();
            this.sections = sections.map((section) => ({
                ...section,
                items: section.items.map((item, index) => ({
                    ...item,
                    key: `${section.key}-${index}`,
                    badgeClass: STATE_CLASS[item.state] ?? STATE_CLASS.neutral
                }))
            }));
        } catch (error) {
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    handleRefresh() {
        this.load();
    }
}
