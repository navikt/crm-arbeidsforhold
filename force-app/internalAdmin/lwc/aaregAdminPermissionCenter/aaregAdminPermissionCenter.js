import { LightningElement } from 'lwc';
import canViewUsers from '@salesforce/apex/AAREG_AdminPermissionController.canViewUsers';

export default class AaregAdminPermissionCenter extends LightningElement {
    showUsers = false;
    checked = false;

    get usersLocked() {
        return this.checked && !this.showUsers;
    }

    async connectedCallback() {
        try {
            this.showUsers = await canViewUsers();
        } catch {
            this.showUsers = false;
        } finally {
            this.checked = true;
        }
    }
}
