import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getUsers from '@salesforce/apex/AAREG_AdminPermissionController.getUsers';
import getUserAccess from '@salesforce/apex/AAREG_AdminPermissionController.getUserAccess';

const STATUS_LABELS = { error: 'Feil', warning: 'Åtvaring', info: 'Merknad', ok: 'OK' };
const STATUS_RANK = { error: 0, warning: 1, info: 2, ok: 3 };
const ALL = 'all';
const errorText = (error) => error?.body?.message ?? error?.message ?? 'Ukjend feil';

export default class AaregAdminUserAccess extends NavigationMixin(LightningElement) {
    users = [];
    statusFilter = ALL;
    searchTerm = '';
    includeInactive = false;
    selectedUserId;
    access;
    accessError;
    accessLoading = false;
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            this.users = (await getUsers()) ?? [];
        } catch (error) {
            this.error = errorText(error);
        } finally {
            this.loading = false;
        }
    }

    get summary() {
        const active = this.users.filter((user) => user.isActive);
        return [
            { key: 'total', label: 'Aktive brukarar', value: active.length },
            { key: 'error', label: 'Med feil', value: this.users.filter((user) => user.status === 'error').length },
            {
                key: 'warning',
                label: 'Med åtvaringar',
                value: this.users.filter((user) => user.status === 'warning').length
            },
            { key: 'inactive', label: 'Inaktive med løyve', value: this.users.length - active.length }
        ];
    }

    get statusOptions() {
        return [
            { label: 'Alle', value: ALL },
            { label: 'Feil', value: 'error' },
            { label: 'Åtvaring', value: 'warning' },
            { label: 'Merknad', value: 'info' },
            { label: 'OK', value: 'ok' }
        ];
    }

    get filteredUsers() {
        const term = this.searchTerm.trim().toLowerCase();
        return this.users
            .filter((user) => this.includeInactive || user.isActive)
            .filter((user) => this.statusFilter === ALL || user.status === this.statusFilter)
            .filter((user) => {
                if (!term) {
                    return true;
                }
                const permissions = (user.assignments ?? []).map((assignment) => assignment.apiName).join(' ');
                return `${user.name} ${user.username} ${user.profileName ?? ''} ${permissions}`
                    .toLowerCase()
                    .includes(term);
            })
            .sort(
                (left, right) =>
                    STATUS_RANK[left.status] - STATUS_RANK[right.status] || left.name.localeCompare(right.name)
            )
            .map((user) => ({
                ...user,
                statusLabel: STATUS_LABELS[user.status],
                statusClass: `status status_${user.status}`,
                rowClass: user.userId === this.selectedUserId ? 'row_selected' : '',
                permissionText: (user.assignments ?? []).map((assignment) => assignment.label).join(', '),
                issueCount: (user.issues ?? []).length,
                lastLoginText: user.lastLogin ? new Date(user.lastLogin).toLocaleDateString('nb-NO') : 'Aldri',
                activeText: user.isActive ? 'Aktiv' : 'Inaktiv'
            }));
    }

    get hasUsers() {
        return this.filteredUsers.length > 0;
    }

    get showEmpty() {
        return !this.loading && !this.error && !this.hasUsers;
    }

    get selectedUser() {
        const user = this.users.find((candidate) => candidate.userId === this.selectedUserId);
        if (!user) {
            return undefined;
        }
        return {
            ...user,
            hasIssues: user.issues?.length > 0,
            issues: (user.issues ?? []).map((issue, index) => ({
                ...issue,
                key: `${index}`,
                levelLabel: STATUS_LABELS[issue.level],
                levelClass: `status status_${issue.level}`
            })),
            assignments: (user.assignments ?? []).map((assignment) => ({
                ...assignment,
                expiresText: assignment.expiresOn ?? 'Ingen'
            }))
        };
    }

    get accessObjects() {
        return (this.access?.objects ?? []).map((grant) => ({
            ...grant,
            sourcesText: grant.sources?.length ? grant.sources.join(', ') : '–',
            rowClass: grant.canRead ? '' : 'slds-text-color_weak'
        }));
    }

    get accessPermissions() {
        return [...(this.access?.customPermissions ?? []), ...(this.access?.apps ?? [])].map((grant) => ({
            ...grant,
            grantedText: grant.granted ? 'Ja' : 'Nei',
            sourcesText: grant.sources?.length ? grant.sources.join(', ') : '–'
        }));
    }

    get sourcesText() {
        return (this.access?.sources ?? []).join(', ');
    }

    handleStatus(event) {
        this.statusFilter = event.detail.value;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value ?? '';
    }

    handleInactive(event) {
        this.includeInactive = event.target.checked;
    }

    async handleSelect(event) {
        this.selectedUserId = event.currentTarget.dataset.id;
        this.access = undefined;
        this.accessError = undefined;
        this.accessLoading = true;
        try {
            this.access = await getUserAccess({ userId: this.selectedUserId });
        } catch (error) {
            this.accessError = errorText(error);
        } finally {
            this.accessLoading = false;
        }
    }

    handleOpenUser() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/lightning/setup/ManageUsers/page?address=%2F${this.selectedUserId}%3Fnoredirect%3D1%26isUserEntityOverride%3D1`
            }
        });
    }

    handleClose() {
        this.selectedUserId = undefined;
        this.access = undefined;
    }
}
