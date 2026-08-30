public with sharing class VRT_CLS_VehicleSearchService {

    @AuraEnabled(cacheable=false)
    public static List<VRT_Vehicle__c> searchVehicles(String searchText) {

        if (!Schema.sObjectType.VRT_Vehicle__c.isAccessible()) {
        throw new SecurityException(
            'No tienes permisos para consultar vehículos.'
        );
        }
        
        if (String.isBlank(searchText)) {
            return new List<VRT_Vehicle__c>();
        }

        String searchPattern = '*' + String.escapeSingleQuotes(searchText.trim()) + '*';

        List<List<SObject>> searchResults = [
            FIND :searchPattern
            IN ALL FIELDS
            RETURNING VRT_Vehicle__c(
                Id,
                Name,
                VRT_TXT_LicensePlate__c,
                VRT_TXT_Brand__c,
                VRT_TXT_Model__c
                LIMIT 20
            )
        ];

        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.READABLE,
                searchResults[0]
            );

        return (List<VRT_Vehicle__c>) accessDecision.getRecords();
    }
}