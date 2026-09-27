// Recibe los Rentals del Trigger y decide qué servicios ejecutar.
// Separo orquestación de lógica de negocio.

public with sharing class VRT_TRG_RentalHandler {
    
    //En after actuo despues de guardar

    public static void onAfterInsert(List<VRT_Rental__c> newRentals) {
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(newRentals);
    }        
    
    public static void onAfterUpdate(
    Map<Id, VRT_Rental__c> oldMap,
    Map<Id, VRT_Rental__c> newMap
    ) {

        VRT_CLS_ApprovalService.updateRejectionReasons(
            oldMap,
            newMap
        );
        
        VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);
        // Enqueue job para crear facturas para los alquileres completados
        Set<Id> rentalIdsToInvoice = new Set<Id>();

        for (VRT_Rental__c rental : newMap.values()) {
            VRT_Rental__c oldRental = oldMap.get(rental.Id);

            if (
                oldRental.VRT_SEL_Status__c == 'En curso' &&
                rental.VRT_SEL_Status__c == 'Completado'
            ) {
                rentalIdsToInvoice.add(rental.Id);
            }
        }

        if (!rentalIdsToInvoice.isEmpty()) {
            System.enqueueJob(new VRT_CLS_InvoiceQueueable(rentalIdsToInvoice));
        }
    }

    // En Before compruebo antes de guardar

    public static void onBeforeInsert(List<VRT_Rental__c> newRentals) {
        VRT_CLS_RentalService.validateVehicleAvailability(
            newRentals,
            null
        );
        
        VRT_CLS_RentalService.calculateRentalPrices(newRentals);
    }

    public static void onBeforeUpdate(
        Map<Id,VRT_Rental__c> oldMap,
        Map<Id,VRT_Rental__c> newMap) 
    {
        VRT_CLS_RentalService.validateStatusTransition(
        oldMap,
        newMap
        );
        VRT_TRG_RentalHandlerHelper.setActualReturnDateWhenCompleted(
        oldMap,
        newMap
        );
        VRT_CLS_RentalService.validateVehicleAvailability(
        new List<VRT_Rental__c>(newMap.values()),
        oldMap
        );
        
        VRT_CLS_RentalService.calculateRentalPrices(
        new List<VRT_Rental__c>(newMap.values())
        );

        VRT_CLS_RentalService.updateApprovalStatusForAmountChange(
            new List<VRT_Rental__c>(newMap.values())
        );
    }
}