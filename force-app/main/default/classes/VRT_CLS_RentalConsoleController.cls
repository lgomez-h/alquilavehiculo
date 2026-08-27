public with sharing class VRT_CLS_RentalConsoleController {

    @AuraEnabled(cacheable=true)
    public static List<VRT_Rental__c> getActiveRentals(Id accountId) {

        return VRT_CLS_RentalService.getActiveRentals(accountId);
    }

    @AuraEnabled
    public static List<VRT_Vehicle__c> getAvailableVehicles(
        Date startDate,
        Date endDate
    ) {
        return VRT_CLS_RentalService.getAvailableVehicles(startDate, endDate);
    }

    @AuraEnabled(cacheable=true)
    public static Decimal simulateRentalPrice(
        Id accountId,
        Id vehicleId,
        Date startDate,
        Date endDate
    ) {
        return VRT_CLS_RentalService.simulateRentalPrice(
            accountId,
            vehicleId,
            startDate,
            endDate
        );
    }

    @AuraEnabled
    public static VRT_Rental__c createRental(
        Id accountId,
        Id vehicleId,
        Date startDate,
        Date endDate
    ) {
        return VRT_CLS_RentalService.createRental(
            accountId,
            vehicleId,
            startDate,
            endDate
        );
    }
    
}   