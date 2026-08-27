import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getActiveRentals
    from '@salesforce/apex/VRT_CLS_RentalConsoleController.getActiveRentals';
import getAvailableVehicles
    from '@salesforce/apex/VRT_CLS_RentalConsoleController.getAvailableVehicles';
import simulateRentalPrice
    from '@salesforce/apex/VRT_CLS_RentalConsoleController.simulateRentalPrice';
import createRental
    from '@salesforce/apex/VRT_CLS_RentalConsoleController.createRental';


const COLUMNS = [
    {
        label: 'Marca',
        fieldName: 'vehicleBrand',
        type: 'text',
        sortable: true
    },
    {
        label: 'Matrícula',
        fieldName: 'vehicleLicensePlate',
        type: 'text',
        sortable: true
    },
    {
        label: 'Estado',
        fieldName: 'VRT_SEL_Status__c',
        type: 'text',
        sortable: true
    },
    {
        label: 'Fecha inicio',
        fieldName: 'VRT_DAT_InitialDate__c',
        type: 'date',
        sortable: true
    },
    {
        label: 'Fecha fin',
        fieldName: 'VRT_DAT_FinalDate__c',
        type: 'date',
        sortable: true
    },
    {
        label: 'Coste total',
        fieldName: 'VRT_DIV_TotalCost__c',
        type: 'currency',
        sortable: true
    }
];
export default class RentalOperationsConsole extends LightningElement {

    @api recordId;

    rentals;
    rentalsError;
    error;
    columns = COLUMNS;
    sortedBy;
    sortDirection;
    allRentals;
    showNewRentalForm = false;
    startDate;
    endDate;
    availableVehicles;
    vehicleOptions = [];
    selectedVehicleId;
    dateError;
    simulatedPrice;
    wiredRentalsResult;
    hasSearchedVehicles = false;
    
    @wire(getActiveRentals, { accountId: '$recordId' })
    wiredRentals(result) {
        this.wiredRentalsResult = result;
        
        const { data, error } = result;
    
        if (data) {
        const transformedRentals = data.map(rental => ({
            ...rental,
            vehicleBrand:
                rental.VRT_LKP_Vehicle__r?.VRT_TXT_Brand__c,
            vehicleLicensePlate:
                rental.VRT_LKP_Vehicle__r?.VRT_TXT_LicensePlate__c
     }));
     
        this.allRentals = transformedRentals;
        this.rentals = [...transformedRentals];
        this.rentalsError = undefined;
        } else if (error) {
            this.rentalsError = error;
            this.rentals = undefined;
        }
    }

    filters = {
    status: 'Todos',
    brand: 'Todas',
    licensePlate: ''
    };

    get statusOptions() {
    return [
        { label: 'Todos', value: 'Todos' },
        { label: 'Reservado', value: 'Reservado' },
        { label: 'En curso', value: 'En curso' }
        ];
    }

    get brandOptions() {
        const brands = [...new Set(
            this.allRentals?.map(rental => rental.vehicleBrand).filter(Boolean)
        )];

        return [
            { label: 'Todas', value: 'Todas' },
            ...brands.map(brand => ({
                label: brand,
            value: brand
            }))
        ];
    }

    handleStatusFilter(event) {
    this.filters = {
        ...this.filters,
        status: event.detail.value
    };

    this.applyFilters();
    }

    handleBrandFilter(event) {
    this.filters = {
        ...this.filters,
        brand: event.detail.value
    };

    this.applyFilters();
    }

    handleLicensePlateFilter(event) {
    this.filters = {
        ...this.filters,
        licensePlate: event.target.value
    };

    this.applyFilters();
    }
    

    handleSort(event) {
    
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;

        this.applySorting();
    }

    applySorting() {
        if (!this.sortedBy || !this.sortDirection) {
            return;
        }
        
        const sortedData = [...this.rentals];

        sortedData.sort((a, b) => {
            const valueA = a[this.sortedBy];
            const valueB = b[this.sortedBy];

            if (valueA === valueB) {
                return 0;
            }

            return valueA > valueB ? 1 : -1;
        });

        if (this.sortDirection === 'desc') {
            sortedData.reverse();
        }

        this.rentals = sortedData;
    }

    applyFilters() {
        
        if (!this.allRentals) {
        return;
        }

        this.rentals = this.allRentals.filter(rental => {

            const matchesStatus =
                this.filters.status === 'Todos' ||
                rental.VRT_SEL_Status__c === this.filters.status;

            const matchesBrand =
                this.filters.brand === 'Todas' ||
                rental.vehicleBrand === this.filters.brand;

            const matchesLicensePlate =
                !this.filters.licensePlate ||
                rental.vehicleLicensePlate
                    ?.toLowerCase()
                    .includes(this.filters.licensePlate.toLowerCase());

            return (
                matchesStatus &&
                matchesBrand &&
                matchesLicensePlate
            );
        });
        this.applySorting();
    }

    handleClearFilters() {
        this.filters = {
            status: 'Todos',
            brand: 'Todas',
            licensePlate: ''
        };

        this.applyFilters();
    }

    handleNewRental() {
    this.showNewRentalForm = true;
    }

    handleStartDateChange(event) {
    this.startDate = event.target.value;
    this.endDate = undefined;
    this.loadAvailableVehicles();
    }

    handleEndDateChange(event) {
    this.endDate = event.target.value;
    this.loadAvailableVehicles();
    }

    loadAvailableVehicles() {

        const today = new Date().toISOString().split('T')[0];

        this.availableVehicles = [];
        this.vehicleOptions = [];
        this.selectedVehicleId = undefined;
        this.simulatedPrice = undefined;
        this.dateError = undefined;
        
        if (this.startDate && this.startDate < today) {
            this.dateError =
                'La fecha de inicio no puede ser anterior a hoy.';
            return;
        }

        if (!this.startDate || !this.endDate) {
            return;
        }
        
        if (this.startDate >= this.endDate) {
            this.dateError =
                'La fecha fin debe ser posterior a la fecha inicio.';
            return;
        }
        
        getAvailableVehicles({
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(result => {
            this.hasSearchedVehicles = true;
            this.availableVehicles = result;

            this.vehicleOptions = result.map(vehicle => ({
                label: `${vehicle.VRT_TXT_Brand__c} - ${vehicle.VRT_TXT_LicensePlate__c}`,
                value: vehicle.Id
            }));
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error al cargar vehículos',
                    message:
                        error.body?.message ||
                        'No se han podido cargar los vehículos disponibles.',
                    variant: 'error'
                })
            );
        });
    }

    handleVehicleChange(event) {
    this.selectedVehicleId = event.detail.value;
    this.simulatedPrice = undefined;
    }

    handleSimulatePrice() {

    if (
        !this.recordId ||
        !this.selectedVehicleId ||
        !this.startDate ||
        !this.endDate
    ) {
        return;
    }

    simulateRentalPrice({
        accountId: this.recordId,
        vehicleId: this.selectedVehicleId,
        startDate: this.startDate,
        endDate: this.endDate
    })
        .then(result => {
            this.simulatedPrice = result;
        })
        .catch(error => {
            this.simulatedPrice = undefined;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error al simular el precio',
                    message:
                        error.body?.message ||
                        'No se ha podido calcular el precio estimado.',
                    variant: 'error'
                })
            );
        });
    }

    resetNewRentalForm() {
        this.startDate = undefined;
        this.endDate = undefined;
        this.selectedVehicleId = undefined;
        this.vehicleOptions = [];
        this.availableVehicles = [];
        this.simulatedPrice = undefined;
        this.dateError = undefined;
        this.showNewRentalForm = false;
        this.hasSearchedVehicles = false;
    }

    handleCancelRental(){
        this.resetNewRentalForm();
    }

    handleCreateRental() {
        if (
            !this.recordId ||
            !this.selectedVehicleId ||
            !this.startDate ||
            !this.endDate
        ) {
            return;
        }


        createRental({
            accountId: this.recordId,
            vehicleId: this.selectedVehicleId,
            startDate: this.startDate,
            endDate: this.endDate
        })

        .then(() => {
            return refreshApex(this.wiredRentalsResult);
        })
        
        .then(() => {
            this.resetNewRentalForm();

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Alquiler creado',
                    message: 'El alquiler se ha creado correctamente.',
                    variant: 'success'
                })
            );
        })

        .catch(error => {
            this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error al crear el alquiler',
                        message: error.body?.message || 'Se ha producido un error.',
                        variant: 'error'
                    })
                );
        });
    }

    get isEndDateDisabled() {
        if (!this.startDate) {
            return true;
        }

        const today = new Date().toISOString().split('T')[0];

        return this.startDate < today;
    }

    get areRentalActionsDisabled() {
        return (
            !this.startDate ||
            !this.endDate ||
            !this.selectedVehicleId ||
            this.dateError
        );
    }

    get noAvailableVehicles() {
        return (
            this.hasSearchedVehicles &&
            this.availableVehicles?.length === 0
        );
}
}