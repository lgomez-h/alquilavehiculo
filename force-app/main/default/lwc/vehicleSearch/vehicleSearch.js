import { LightningElement } from 'lwc';

import searchVehicles
    from '@salesforce/apex/VRT_CLS_VehicleSearchService.searchVehicles';
    
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
        label: 'License Plate',
        fieldName: 'vehicleUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'VRT_TXT_LicensePlate__c' },
            target: '_blank'
        }
    },
    {
        label: 'Brand',
        fieldName: 'VRT_TXT_Brand__c',
        type: 'text'
    },
    {
        label: 'Model',
        fieldName: 'VRT_TXT_Model__c',
        type: 'text'
    }
];

export default class VehicleSearch extends LightningElement {

    searchText = '';
    vehicles = [];
    columns = COLUMNS;
    isLoading = false;
    hasSearched = false;

    handleSearchTextChange(event) {
        this.searchText = event.target.value;
            
        this.vehicles = [];
        this.hasSearched = false;
    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    async handleSearch() {

        this.isLoading = true;
        
        
        try {
            //throw new Error('Test error');
            // await new Promise(resolve => setTimeout(resolve, 2000));
            const vehicles = await searchVehicles({    
            searchText: this.searchText
            });

            this.vehicles = vehicles.map(vehicle => ({
                ...vehicle,
                vehicleUrl: '/' + vehicle.Id
            }));
            this.hasSearched = true;
            console.log(this.vehicles);
        }
        catch (error) {

        console.error(error);

        const toast = new ShowToastEvent({
            title: 'Error',
            message: 'Unable to search vehicles.',
            variant: 'error'
        });

        this.dispatchEvent(toast);
        }
        finally {
            this.isLoading = false;
        }
    }
}