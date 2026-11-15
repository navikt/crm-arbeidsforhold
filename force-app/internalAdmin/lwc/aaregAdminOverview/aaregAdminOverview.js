import { LightningElement } from 'lwc';
import getOverview from '@salesforce/apex/AAREG_AdminOverviewController.getOverview';
import getTileRecords from '@salesforce/apex/AAREG_AdminOverviewController.getTileRecords';

const COLUMNS = [
    { label: 'Post', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'name' } } },
    { label: 'Detalj', fieldName: 'detail' },
    {
        label: 'Sist endra',
        fieldName: 'lastModified',
        type: 'date',
        typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }
    }
];

function errorMessage(error) {
    return error?.body?.message ?? error?.message ?? 'Ukjend feil';
}

export default class AaregAdminOverview extends LightningElement {
    tiles = [];
    error;
    loading = true;
    selectedTile;
    rows = [];
    rowsError;
    columns = COLUMNS;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            const tiles = await getOverview();
            this.tiles = tiles.map((tile) => ({
                ...tile,
                breakdownText: (tile.breakdown ?? []).map((item) => `${item.label}: ${item.count}`).join(' · ')
            }));
        } catch (error) {
            this.error = errorMessage(error);
        } finally {
            this.loading = false;
        }
    }

    async handleShowRecords(event) {
        const key = event.target.dataset.key;
        this.selectedTile = this.tiles.find((tile) => tile.key === key);
        this.rows = [];
        this.rowsError = undefined;
        try {
            const rows = await getTileRecords({ key });
            this.rows = rows.map((row) => ({
                ...row,
                recordUrl: `/lightning/r/${this.selectedTile.objectApiName}/${row.id}/view`
            }));
        } catch (error) {
            this.rowsError = errorMessage(error);
        }
    }

    handleRefresh() {
        this.selectedTile = undefined;
        this.load();
    }

    get hasNoRows() {
        return !this.rowsError && this.rows.length === 0;
    }
}
