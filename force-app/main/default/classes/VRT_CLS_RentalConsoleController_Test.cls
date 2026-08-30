@IsTest
private class VRT_CLS_RentalConsoleController_Test {

    @IsTest
    static void testGetActiveRentals() {

        // ========= ARRANGE =========

        Account account = new Account(
            Name = 'Cliente Consola Test'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '7777XXX',
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
            VRT_DAT_FinalDate__c = Date.today().addDays(7)
        );
        insert rental;

        // ========= ACT =========

        Test.startTest();

        List<VRT_Rental__c> result =
            VRT_CLS_RentalConsoleController.getActiveRentals(
                account.Id
            );

        Test.stopTest();

        // ========= ASSERT =========

        System.assertEquals(
            1,
            result.size(),
            'El Controller debe devolver el alquiler activo de la Account.'
        );

        System.assertEquals(
            rental.Id,
            result[0].Id,
            'El alquiler devuelto debe ser el esperado.'
        );
    }
    @IsTest
static void testGetAvailableVehicles() {

    // ========= ARRANGE =========

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '7777AAA',
        VRT_TXT_Brand__c = 'Toyota',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2022, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );

    insert vehicle;

    Date startDate = Date.today().addDays(10);
    Date endDate = Date.today().addDays(15);

    // ========= ACT =========

    Test.startTest();

    List<VRT_Vehicle__c> result =
        VRT_CLS_RentalConsoleController.getAvailableVehicles(
            startDate,
            endDate
        );

    Test.stopTest();

    // ========= ASSERT =========

    Set<Id> resultIds = new Set<Id>();

    for (VRT_Vehicle__c availableVehicle : result) {
        resultIds.add(availableVehicle.Id);
    }

    System.assertEquals(
        true,
        resultIds.contains(vehicle.Id),
        'El Controller debe devolver el vehículo disponible.'
    );
    }

    @IsTest
static void testSimulateRentalPrice() {

    // ========= ARRANGE =========

    Account account = new Account(
        Name = 'Cliente Simulación'
    );
    insert account;

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '5555EEE',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );
    insert vehicle;

    Date startDate = Date.newInstance(2026, 7, 1);
    Date endDate = Date.newInstance(2026, 7, 4);

    // ========= ACT =========

    Test.startTest();

    Decimal result =
        VRT_CLS_RentalConsoleController.simulateRentalPrice(
            account.Id,
            vehicle.Id,
            startDate,
            endDate
        );

    Test.stopTest();

    // ========= ASSERT =========

    System.assertEquals(
        240,
        result,
        'El Controller debe devolver el precio simulado correctamente.'
    );
    }

    @IsTest
static void testCreateRental() {

    // ========= ARRANGE =========

    Account account = new Account(
        Name = 'Cliente Controller Create'
    );
    insert account;

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '3434HHH',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );
    insert vehicle;

    Date startDate = Date.today().addDays(1);
    Date endDate = Date.today().addDays(4);

    // ========= ACT =========

    Test.startTest();

    VRT_Rental__c result =
        VRT_CLS_RentalConsoleController.createRental(
            account.Id,
            vehicle.Id,
            startDate,
            endDate
        );

    Test.stopTest();

    // ========= ASSERT =========

    System.assertNotEquals(
        null,
        result.Id,
        'El Controller debe devolver el alquiler creado.'
    );

    VRT_Rental__c savedRental = [
        SELECT
            VRT_SEL_Status__c,
            VRT_SEL_PaymentStatus__c,
            VRT_DIV_TotalCost__c
        FROM VRT_Rental__c
        WHERE Id = :result.Id
    ];

    System.assertEquals(
        'Reservado',
        savedRental.VRT_SEL_Status__c
    );

    System.assertEquals(
        'Pendiente',
        savedRental.VRT_SEL_PaymentStatus__c
    );

    System.assertNotEquals(
    null,
    savedRental.VRT_DIV_TotalCost__c
    );

    System.assert(
        savedRental.VRT_DIV_TotalCost__c > 0
    );
    }
}