import helpers from './helpers.js';
import fetchSalesRepPerformanceReport
    from '@salesforce/apex/UserController.fetchSalesRepPerformanceReport';
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Owner', fieldName: 'salesRepName', type: 'text',
        sortable: true},

    { label: 'Total Leads', fieldName: 'totalLeads', type: 'number',
        sortable: true,
        typeAttributes: { maximumFractionDigits: 0 }},

    { label: 'Total Opps.', fieldName: 'totalOpps', type: 'number',
        sortable: true,
        typeAttributes: { maximumFractionDigits: 0 }},

    { label: 'Conv Rate', fieldName: 'conversionRate', type: 'percent',
        sortable: true,
        typeAttributes: { minimumFractionDigits: 2 }},

    { label: 'Max Created Date (Opp)', fieldName: 'latestCreatedDate',
        type: 'date-local', sortable: true,
        typeAttributes: { year: 'numeric', month: 'numeric', day: 'numeric' },
        cellAttributes: { alignment: 'right' }},

    { label: 'Total Val (Opp)', fieldName: 'totalValue', type: 'currency',
        sortable: true,
        typeAttributes: { currencyCode: 'USD' }},
];

export default class SalesRepPerformanceReport extends LightningElement {
    data            = [];
    columns         = columns;
    isLoading       = true;

    sortedBy        = 'totalValue';
    sortDirection   = 'desc';

    // In JavaScript, 2 corresponds to March
    startDateField  = new Date(2020, 2, 1);
    endDateField    = new Date(2020, 2, 31);

    // Initialize date ranges so that date picker will show allowed date values.
    // Only 31-day ranges are allowed.
    // These fields will be derived from startDateField and endDateField.
    // Provides validation that startDateField < endDateField as well.
    minStartDate    = this.startDateField.toISOString().substring(0, 10);
    minEndDate      = this.startDateField.toISOString().substring(0, 10);
    maxStartDate    = this.endDateField.toISOString().substring(0, 10);
    maxEndDate      = this.endDateField.toISOString().substring(0, 10);

    @wire(fetchSalesRepPerformanceReport,
        { startDate: '$startDateField', endDate: '$endDateField' })
    wiredSalesRepPerformanceReport({ error, data }) {
        if (data) {
            const cloneData = [...data];

            cloneData.sort(helpers.sortBy(
                this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));

            this.data = cloneData;
            this.isLoading = false;
        } else if (error) {
            const toastEvent = new ShowToastEvent({
                title:      error.body.message,
                variant:    'error',
                mode:       'sticky',
            });
            this.dispatchEvent(toastEvent);

            this.isLoading = false;
        }
    }

    connectedCallback() {
        // this.startDateInput = this.template.querySelector('.startDate');
        // this.endDateInput = this.template.querySelector('.endDate');

        // this.fetchData();
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(helpers.sortBy(
            sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleChange(event) {
        this.isLoading = true;

        if (event.target.name === 'startDate') {
            this.startDateField = new Date(event.target.value);

            this.minEndDate =
                this.startDateField.toISOString().substring(0, 10);
            this.maxEndDate = helpers.addDays(this.startDateField, 31)
                .toISOString().substring(0, 10);
        } else if (event.target.name === 'endDate') {
            this.endDateField = new Date(event.target.value);

            this.minStartDate = helpers.addDays(this.endDateField, -30)
                .toISOString().substring(0, 10);
            this.maxStartDate =
                this.endDateField.toISOString().substring(0, 10);
        }
    }

    get startDate() {
        return this.startDateField.toISOString().substring(0, 10);
    }

    get endDate() {
        return this.endDateField.toISOString().substring(0, 10);
    }

    sortBy(field, reverse) {
        const key = x => x[field];

        return (a, b) => {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
}
