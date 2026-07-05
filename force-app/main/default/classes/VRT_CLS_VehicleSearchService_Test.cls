@IsTest
private class VRT_CLS_VehicleSearchService_Test {

    @IsTest
    static void testSearchVehiclesFound() {
        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '9999TST',
            VRT_TXT_Brand__c = 'Toyota',
            VRT_TXT_Model__c = 'Corolla',
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_SEL_Status__c = 'Listo',
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_NUM_Passengers__c = 5,
            VRT_FLG_Available__c = true,
            VRT_NUM_Usage__c = 0,
            VRT_NUM_Mileage__c = 0
        );
        insert vehicle;

        Test.setFixedSearchResults(new List<Id>{ vehicle.Id });

        List<VRT_Vehicle__c> results =
            VRT_CLS_VehicleSearchService.searchVehicles('Toyota');

        System.assertEquals(1, results.size());
        System.assertEquals(vehicle.Id, results[0].Id);
    }

    @IsTest
    static void testSearchVehiclesBlankText() {
        List<VRT_Vehicle__c> results =
            VRT_CLS_VehicleSearchService.searchVehicles('');

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testSearchVehiclesNullText() {
        List<VRT_Vehicle__c> results =
            VRT_CLS_VehicleSearchService.searchVehicles(null);

        System.assertEquals(0, results.size());
    }
}