@IsTest
public class VRT_CLS_CheckVehicleRevision_Test {
    @IsTest
    static void testBatchRevision() {
        Integer currentYear = Date.today().year();

        VRT_Vehicle__c coche = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '1234AAA',
            VRT_TXT_Brand__c         = 'Ford',
            VRT_SEL_VehicleType__c   = 'Coche',
            VRT_SEL_Status__c        = 'Listo',
            VRT_SEL_EnergyType__c    = 'Gasolina',
            VRT_NUM_Passengers__c    = 4,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(currentYear-5,1,1),
            VRT_FLG_NeedsInspection__c  = false
        );
        VRT_Vehicle__c moto = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '2345BBB',
            VRT_TXT_Brand__c         = 'Honda',
            VRT_SEL_VehicleType__c   = 'Moto',
            VRT_SEL_Status__c        = 'Listo',
            VRT_SEL_EnergyType__c    = 'Gasolina',
            VRT_NUM_Passengers__c    = 2,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(currentYear-3,1,1),
            VRT_FLG_NeedsInspection__c  = false
        );
        VRT_Vehicle__c nuevo = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '3456CCC',
            VRT_TXT_Brand__c         = 'Renault',
            VRT_SEL_VehicleType__c   = 'Coche',
            VRT_SEL_Status__c        = 'Listo',
            VRT_SEL_EnergyType__c    = 'Diesel',
            VRT_NUM_Passengers__c    = 5,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(currentYear,1,1),
            VRT_FLG_NeedsInspection__c  = false
        );
        insert new List<VRT_Vehicle__c>{coche, moto, nuevo};

        // Ejecuta el batch
        Test.startTest();
        Database.executeBatch(new VRT_CLS_CheckVehicleRevision(), 200);
        Test.stopTest();

        coche = [SELECT VRT_FLG_NeedsInspection__c FROM VRT_Vehicle__c WHERE Id = :coche.Id];
        moto  = [SELECT VRT_FLG_NeedsInspection__c FROM VRT_Vehicle__c WHERE Id = :moto.Id];
        nuevo = [SELECT VRT_FLG_NeedsInspection__c FROM VRT_Vehicle__c WHERE Id = :nuevo.Id];
        System.assertEquals(true, coche.VRT_FLG_NeedsInspection__c, 'El coche viejo debe estar a true');
        System.assertEquals(true, moto.VRT_FLG_NeedsInspection__c, 'La moto también');
        System.assertEquals(false, nuevo.VRT_FLG_NeedsInspection__c, 'El coche nuevo debe estar a false');
    }
}