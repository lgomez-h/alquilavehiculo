@IsTest
private class VRT_CLS_AvailabilityService_Test {

    @IsTest
    static void testReturnsUnavailableVehicleWhenDatesOverlap() {

        // ARRANGE
        Account account = new Account(
            Name = 'Test Availability Account'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '9999ZZZ',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false,
        VRT_FLG_Available__c = true
    );

        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(5),
            VRT_DAT_FinalDate__c = Date.today().addDays(10)
        );
        insert rental;

        // ACT
        Set<Id> unavailableVehicleIds =
            VRT_CLS_AvailabilityService.getUnavailableVehicleIds(
                Date.today().addDays(7),
                Date.today().addDays(12)
            );

        // ASSERT
        System.assert(
            unavailableVehicleIds.contains(vehicle.Id),
            'El vehículo debería estar ocupado porque las fechas se solapan.'
        );
    }


    @IsTest
    static void testDoesNotReturnVehicleWithoutOverlap() {

        // ARRANGE
        Account account = new Account(
            Name = 'Test Availability Account'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '9999ZZZ',
                VRT_TXT_Brand__c = 'Ford',
                VRT_SEL_VehicleType__c = 'Coche',
                VRT_SEL_Status__c = 'Listo',
                VRT_SEL_EnergyType__c = 'Gasolina',
                VRT_NUM_Passengers__c = 4,
                VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
                VRT_FLG_NeedsInspection__c = false,
                VRT_FLG_Available__c = true
            );

        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(5),
            VRT_DAT_FinalDate__c = Date.today().addDays(10)
        );
        insert rental;

        // ACT
        Set<Id> unavailableVehicleIds =
            VRT_CLS_AvailabilityService.getUnavailableVehicleIds(
                Date.today().addDays(15),
                Date.today().addDays(20)
            );

        // ASSERT
        System.assert(
            !unavailableVehicleIds.contains(vehicle.Id),
            'El vehículo debería estar disponible porque no existe solapamiento.'
        );
    }


    @IsTest
    static void testAllowsSameDayEndStart() {

        // ARRANGE
        Account account = new Account(
            Name = 'Test Availability Account'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '9999ZZZ',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false,
        VRT_FLG_Available__c = true
    );

        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(5),
            VRT_DAT_FinalDate__c = Date.today().addDays(10)
        );
        insert rental;

        // ACT
        Set<Id> unavailableVehicleIds =
            VRT_CLS_AvailabilityService.getUnavailableVehicleIds(
                Date.today().addDays(10),
                Date.today().addDays(15)
            );

        // ASSERT
        System.assert(
            !unavailableVehicleIds.contains(vehicle.Id),
            'El vehículo debería estar disponible si un alquiler empieza el mismo día que termina el anterior.'
        );
    }
}