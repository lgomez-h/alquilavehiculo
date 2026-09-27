// Clase que implementa la búsqueda de vehículos.
public with sharing class VRT_CLS_VehicleSearchService {
    //para conectar con LWC
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
        // Escapo los caracteres especiales y agrego comodines para la búsqueda
        String searchPattern = '*' + String.escapeSingleQuotes(searchText.trim()) + '*';
        // Realizo la búsqueda de vehículos utilizando SOSL
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
        // miro si el usuario tiene acceso a los campos de VRT_Vehicle__c y filtro los resultados en consecuencia
        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.READABLE,
                searchResults[0]
            );
        // Devuelvo los registros de vehículos filtrados
        return (List<VRT_Vehicle__c>) accessDecision.getRecords();
    }
}