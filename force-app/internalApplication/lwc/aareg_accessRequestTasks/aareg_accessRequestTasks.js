import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getTasks from '@salesforce/apex/AAREG_AccessRequestTasksController.getTasks';

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
    { label: 'Type', fieldName: 'type', type: 'text', hideDefaultActions: true },
    { label: 'Beskrivelse', fieldName: 'description', type: 'text', wrapText: true, hideDefaultActions: true },
    { label: 'Opprettet', fieldName: 'createdDate', type: 'date', hideDefaultActions: true }
];

export default class Aareg_accessRequestTasks extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    tasks = [];
    error;
    isLoading = true;
    wiredTasksResult;

    @wire(getTasks, { accessRequestId: '$recordId' })
    wiredGetTasks(result) {
        this.wiredTasksResult = result;
        const { data, error } = result;
        this.isLoading = false;

        if (data) {
            this.tasks = data.map((task) => ({
                id: task.Id,
                taskUrl: `/lightning/r/Task/${task.Id}/view`,
                subject: task.Subject,
                type: task.Type,
                description: task.Description,
                createdDate: task.CreatedDate
            }));
            this.error = undefined;
        } else if (error) {
            this.tasks = [];
            this.error = error;
        }
    }

    get hasTasks() {
        return Array.isArray(this.tasks) && this.tasks.length > 0;
    }

    get taskCount() {
        return this.tasks.length;
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredTasksResult);
        } catch (refreshError) {
            this.error = refreshError;
        } finally {
            this.isLoading = false;
        }
    }
}