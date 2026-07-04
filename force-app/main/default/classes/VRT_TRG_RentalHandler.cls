public with sharing class VRT_TRG_RentalHandler {
    
    public static void onAfterInsert(List<VRT_Rental__c> newRentals) {
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(newRentals);
    }        
    public static void onAfterUpdate(
    Map<Id, VRT_Rental__c> oldMap,
    Map<Id, VRT_Rental__c> newMap
    ) {
    VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);

    List<VRT_Rental__c> rentalsToInvoice = new List<VRT_Rental__c>();

    for (VRT_Rental__c rental : newMap.values()) {
        VRT_Rental__c oldRental = oldMap.get(rental.Id);

        if (
            rental.VRT_SEL_Status__c == 'Completado' &&
            oldRental.VRT_SEL_Status__c != 'Completado'
        ) {
            rentalsToInvoice.add(rental);
        }
    }

    if (!rentalsToInvoice.isEmpty()) {
        System.enqueueJob(new VRT_CLS_InvoiceQueueable(rentalsToInvoice));
    }
    }
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
    }
}