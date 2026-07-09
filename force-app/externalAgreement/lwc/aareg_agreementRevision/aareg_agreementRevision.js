import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    {
        label: 'Emne',
        fieldName: 'taskUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'subject' },
            target: '_self'
        }
    },
    { label: 'Beskrivelse', fieldName: 'description', type: 'text', wrapText: true },
    { label: 'Forfallsdato', fieldName: 'dueDate', type: 'date' },
    {
        label: 'Opprettet',
        fieldName: 'createdDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

export default class Aareg_agreementRevision extends NavigationMixin(LightningElement) {
    @api recordId;
    @api cardTitle = 'Loggført aktivitet under revisjon';
    @api taskType = 'Revisjon';

    columns = COLUMNS;
    tasks = [];
    error;
    isLoading = true;
    wiredTasksResult

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Tasks',
        fields: [
            'Task.Id',
            'Task.Subject',
            'Task.CreatedDate',
            'Task.Description',
            'Task.ActivityDate',
            'Task.Type'
        ],
        sortBy: ['-Task.CreatedDate']
    })
    wiredTasks(result) {
        this.wiredTasksResult = result; 
        const { data, error } = result;
        this.isLoading = false;
        if (data) {
            this.tasks = data.records
                .filter(
                    (r) =>
                        r.fields.Type &&
                        r.fields.Type.value === this.taskType
                )
                .map((r) => ({
                    id: r.fields.Id.value,
                    taskUrl: `/lightning/r/Task/${r.fields.Id.value}/view`,
                    subject: r.fields.Subject.value,
                    description: r.fields.Description.value,
                    dueDate: r.fields.ActivityDate.value,
                    createdDate: r.fields.CreatedDate.value
                }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.tasks = [];
        }
    }

    @api
    async refresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredTasksResult);
        } catch (e) {
            this.error = e;
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.refresh();
    }

    get hasTasks() {
        return this.tasks && this.tasks.length > 0;
    }

    get taskCount() {
        return this.tasks ? this.tasks.length : 0;
    }

}