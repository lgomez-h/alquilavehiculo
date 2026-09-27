public without sharing class VRT_CLS_AvailabilityService {
    // Busca vehículos no disponibles para un rango de fechas
    public static Set<Id> getUnavailableVehicleIds(
        Date startDate,
        Date endDate
    ) {

        Set<Id> unavailableVehicleIds = new Set<Id>();

        for (VRT_Rental__c rental : [
            SELECT VRT_LKP_Vehicle__c
            FROM VRT_Rental__c
            WHERE VRT_SEL_Status__c IN ('Reservado', 'En curso')
            AND VRT_DAT_InitialDate__c < :endDate
            AND VRT_DAT_FinalDate__c > :startDate
            AND VRT_LKP_Vehicle__c != null
        ]) {
            unavailableVehicleIds.add(
                rental.VRT_LKP_Vehicle__c
            );
        }

        return unavailableVehicleIds;
    }
}