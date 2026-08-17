@IsTest
private class VRT_CLS_RentalService_Test {
    @testSetup
    static void setupData() {
    Account account = new Account(
        Name = 'Cliente Test'
    );
    insert account;

    Account account2 = new Account(
        Name = 'Cliente Test 2'
    );
    insert account2;

    List<VRT_Rental__c> rentals = new List<VRT_Rental__c>();

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-2),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-2).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-4),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-4).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-6),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-6).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Cancelado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-1),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-1).addDays(2)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-18),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-18).addDays(2)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account2.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-3),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-3).addDays(3)
    ));

    insert rentals;
    }

    @IsTest
static void testCountCompletedRentalsLast12Months() {

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    Integer completedRentals =
        VRT_CLS_RentalService.countCompletedRentalsLast12Months(
            account.Id
        );

    System.assertEquals(
        3,
        completedRentals,
        'Debe contar únicamente los alquileres completados de los últimos 12 meses.'
    );
}

@IsTest
static void testCalculateRentalPricesBulk() {

    // ========= ARRANGE =========

    // Esta Account ya tiene 3 alquileres completados en los últimos
    // 12 meses gracias al @testSetup.
    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    // Creamos UN solo vehículo.
    VRT_Vehicle__c coche = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '9999ZZZ',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );

    insert coche;

    // Creamos 150 Rentals EN MEMORIA.
    // No hacemos insert porque queremos probar directamente
    // calculateRentalPrices(), no todo el trigger.
    List<VRT_Rental__c> rentals = new List<VRT_Rental__c>();

    for (Integer i = 0; i < 150; i++) {
        rentals.add(new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = coche.Id,
            VRT_DAT_InitialDate__c = Date.newInstance(2026, 7, 1),
            VRT_DAT_FinalDate__c = Date.newInstance(2026, 7, 4)
        ));
    }

    // ========= ACT =========

    Test.startTest();

    Integer queriesBefore = Limits.getQueries();

    VRT_CLS_RentalService.calculateRentalPrices(rentals);

    Integer queriesAfter = Limits.getQueries();

    Test.stopTest();

    // ========= ASSERT =========

    // calculateRentalPrices debe necesitar:
    // 1 SOQL para recuperar los Vehicles.
    // 1 SOQL agregada para contar Rentals completados por Account.
    System.assertEquals(
        2,
        queriesAfter - queriesBefore,
        'El cálculo masivo debe realizar solo dos consultas SOQL.'
    );

    // Todos los alquileres deben haber recibido su precio.
    //
    // Julio = temporada Alta
    // Coche = 80 €/día
    // 3 días = 240 €
    // 3 alquileres completados = 5 % descuento
    // 240 - 5 % = 228 €
    for (VRT_Rental__c rental : rentals) {
        System.assertEquals(
            228,
            rental.VRT_DIV_TotalCost__c,
            'Todos los alquileres deben calcular el precio correctamente.'
        );
    }
}
}
