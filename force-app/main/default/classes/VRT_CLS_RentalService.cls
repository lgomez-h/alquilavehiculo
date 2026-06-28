public with sharing class VRT_CLS_RentalService {

    public static Integer countCompletedRentalsLast12Months(
        Id accountId
    ) {
            Integer completedRentals = [
            SELECT COUNT()
            FROM VRT_Rental__c
            WHERE VRT_LKP_Account__c = :accountId
            AND VRT_SEL_Status__c = 'Completado'
            AND VRT_DAT_FinalDate__c >= :Date.today().addMonths(-12)
            ];

    return completedRentals; 


    }

    public static void calculateRentalPrices(
    List<VRT_Rental__c> rentals
    ) {
    Set<Id> vehicleIds = new Set<Id>();

    for (VRT_Rental__c rental : rentals) {
        if (rental.VRT_LKP_Vehicle__c != null) {
            vehicleIds.add(rental.VRT_LKP_Vehicle__c);
        }
    }

    if (vehicleIds.isEmpty()) {
        return;
    }

    Map<Id, VRT_Vehicle__c> vehiclesById =
        new Map<Id, VRT_Vehicle__c>([
            SELECT Id, VRT_SEL_VehicleType__c
            FROM VRT_Vehicle__c
            WHERE Id IN :vehicleIds
        ]);

    for (VRT_Rental__c rental : rentals) {
        if (
            rental.VRT_LKP_Vehicle__c == null ||
            rental.VRT_LKP_Account__c == null ||
            rental.VRT_DAT_InitialDate__c == null ||
            rental.VRT_DAT_FinalDate__c == null
        ) {
            continue;
        }

        VRT_Vehicle__c vehicle =
            vehiclesById.get(rental.VRT_LKP_Vehicle__c);

        if (vehicle == null) {
            continue;
        }

        rental.VRT_DIV_TotalCost__c =
            VRT_CLS_PricingService.calculateFinalPrice(
                vehicle.VRT_SEL_VehicleType__c,
                rental.VRT_DAT_InitialDate__c,
                rental.VRT_DAT_FinalDate__c,
                rental.VRT_LKP_Account__c,
                rental.VRT_DAT_ActualReturnDate__c
            );
    }
    }
}   