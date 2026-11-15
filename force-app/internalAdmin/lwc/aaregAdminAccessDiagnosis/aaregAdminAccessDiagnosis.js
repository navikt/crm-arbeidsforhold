import { LightningElement } from 'lwc';
import getDiagnosis from '@salesforce/apex/AAREG_AdminAccessDiagnosisController.getDiagnosis';

const yesNo = (value) => (value ? 'Ja' : 'Nei');

export default class AaregAdminAccessDiagnosis extends LightningElement {
    diagnosis;
    objects = [];
    customPermissions = [];
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            const diagnosis = await getDiagnosis();
            this.diagnosis = diagnosis;
            this.objects = (diagnosis.objects ?? []).map((access) => ({
                ...access,
                readText: yesNo(access.canRead),
                createText: yesNo(access.canCreate),
                editText: yesNo(access.canEdit),
                rowClass: access.canRead ? '' : 'slds-text-color_error'
            }));
            this.customPermissions = (diagnosis.customPermissions ?? []).map((permission) => ({
                ...permission,
                grantedText: yesNo(permission.granted)
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

    get permissionSetText() {
        const sets = this.diagnosis?.permissionSets ?? [];
        return sets.length ? sets.join(', ') : 'Ingen';
    }
}
