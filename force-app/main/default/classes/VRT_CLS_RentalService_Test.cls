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

@IsTest
static void testGetActiveRentals() {

    // ========= ARRANGE =========

    // Recuperamos la Account creada por @testSetup.
    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    // Creamos un vehículo para relacionarlo con los alquileres.
    VRT_Vehicle__c coche = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '8888YYY',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );

    insert coche;

    // Creamos los dos alquileres que SÍ consideramos activos.
    List<VRT_Rental__c> activeRentals = new List<VRT_Rental__c>();

    activeRentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = coche.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(5),
        VRT_DAT_FinalDate__c = Date.today().addDays(7)
    ));

    activeRentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = coche.Id,
        VRT_SEL_Status__c = 'En curso',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(-1),
        VRT_DAT_FinalDate__c = Date.today().addDays(2)
    ));

    insert activeRentals;

    // ========= ACT =========

    List<VRT_Rental__c> result =
        VRT_CLS_RentalService.getActiveRentals(account.Id);

    // ========= ASSERT =========

    System.assertEquals(
        2,
        result.size(),
        'Debe devolver únicamente los alquileres activos.'
    );
    
    System.assertEquals(
        'Ford',
        result[0].VRT_LKP_Vehicle__r.VRT_TXT_Brand__c,
        'Debe devolver la marca del vehículo relacionado.'
    );

    System.assertEquals(
        '8888YYY',
        result[0].VRT_LKP_Vehicle__r.VRT_TXT_LicensePlate__c,
        'Debe devolver la matrícula del vehículo relacionado.'
    );
}

@IsTest
static void testGetActiveRentalsWithNullAccount() {

    // ========= ACT =========

    List<VRT_Rental__c> result =
        VRT_CLS_RentalService.getActiveRentals(null);

    // ========= ASSERT =========

    System.assertEquals(
        0,
        result.size(),
        'Si no se proporciona una Account, debe devolver una lista vacía.'
    );
}

@IsTest
    static void testVehicleAvailabilityBlocksOverlap() {

        // ========= ARRANGE =========

        Account account = [
            SELECT Id
            FROM Account
            WHERE Name = 'Cliente Test'
            LIMIT 1
        ];

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '4444DDD',
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

        // Alquiler existente: día 5 -> día 10
        VRT_Rental__c existingRental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(5),
            VRT_DAT_FinalDate__c = Date.today().addDays(10)
        );
        insert existingRental;

        // Nuevo alquiler: día 8 -> día 12
        VRT_Rental__c newRental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(8),
            VRT_DAT_FinalDate__c = Date.today().addDays(12)
        );

        // ========= ACT =========

        Test.startTest();

        VRT_CLS_RentalService.validateVehicleAvailability(
            new List<VRT_Rental__c>{ newRental },
            null
        );

        Test.stopTest();

        // ========= ASSERT =========

        System.assertEquals(
            1,
            newRental.getErrors().size(),
            'Debe detectar el solapamiento del vehículo.'
        );
    }

    @IsTest
static void testVehicleAvailabilityAllowsSameDayEndStart() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '3333CCC',
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

    VRT_Rental__c existingRental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(5),
        VRT_DAT_FinalDate__c = Date.today().addDays(10)
    );
    insert existingRental;

    VRT_Rental__c newRental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(10),
        VRT_DAT_FinalDate__c = Date.today().addDays(15)
    );

    // ========= ACT =========

    Test.startTest();

    VRT_CLS_RentalService.validateVehicleAvailability(
        new List<VRT_Rental__c>{ newRental },
        null
    );

    Test.stopTest();

    // ========= ASSERT =========

    System.assertEquals(
        0,
        newRental.getErrors().size(),
        'Debe permitirse que un alquiler empiece el mismo día que termina otro.'
    );
    }

    @IsTest
static void testGetAvailableVehicles() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    VRT_Vehicle__c occupiedVehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '1111AAA',
        VRT_TXT_Brand__c = 'Ford',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );

    VRT_Vehicle__c availableVehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '2222BBB',
        VRT_TXT_Brand__c = 'Toyota',
        VRT_SEL_VehicleType__c = 'Coche',
        VRT_SEL_Status__c = 'Listo',
        VRT_SEL_EnergyType__c = 'Gasolina',
        VRT_NUM_Passengers__c = 4,
        VRT_FLG_Available__c = true,
        VRT_DAT_ManufacturedYear__c = Date.newInstance(2022, 1, 1),
        VRT_FLG_NeedsInspection__c = false
    );

    insert new List<VRT_Vehicle__c>{
        occupiedVehicle,
        availableVehicle
    };

    VRT_Rental__c existingRental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = occupiedVehicle.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(5),
        VRT_DAT_FinalDate__c = Date.today().addDays(10)
    );

    insert existingRental;

    // ========= ACT =========

    Test.startTest();

    List<VRT_Vehicle__c> result =
        VRT_CLS_RentalService.getAvailableVehicles(
            Date.today().addDays(8),
            Date.today().addDays(12)
        );

    Test.stopTest();

    // ========= ASSERT =========

    Set<Id> resultIds = new Set<Id>();

    for (VRT_Vehicle__c vehicle : result) {
        resultIds.add(vehicle.Id);
    }

    System.assertEquals(
        false,
        resultIds.contains(occupiedVehicle.Id),
        'El vehículo con un alquiler solapado no debe estar disponible.'
    );

    System.assertEquals(
        true,
        resultIds.contains(availableVehicle.Id),
        'El vehículo sin alquileres solapados debe estar disponible.'
    );
}
@IsTest
static void testSimulateRentalPrice() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '6666FFF',
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

    // Julio = temporada Alta.
    Date startDate = Date.newInstance(2026, 7, 1);
    Date endDate = Date.newInstance(2026, 7, 4);

    // ========= ACT =========

    Test.startTest();

    Decimal result =
        VRT_CLS_RentalService.simulateRentalPrice(
            account.Id,
            vehicle.Id,
            startDate,
            endDate
        );

    Test.stopTest();

    // ========= ASSERT =========

    System.assertEquals(
        228,
        result,
        'La simulación debe calcular el precio incluyendo el descuento de fidelidad.'
    );
}

@IsTest
static void testCreateRental() {

    // ========= ARRANGE =========

    Account account = new Account(
        Name = 'Cliente Creación'
    );
    insert account;

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '4545GGG',
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

    VRT_Rental__c createdRental =
        VRT_CLS_RentalService.createRental(
            account.Id,
            vehicle.Id,
            startDate,
            endDate
        );

    Test.stopTest();

    // ========= ASSERT =========

    VRT_Rental__c savedRental = [
        SELECT
            Id,
            VRT_LKP_Account__c,
            VRT_LKP_Vehicle__c,
            VRT_SEL_Status__c,
            VRT_SEL_PaymentStatus__c,
            VRT_DIV_TotalCost__c
        FROM VRT_Rental__c
        WHERE Id = :createdRental.Id
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
    savedRental.VRT_DIV_TotalCost__c,
    'El trigger debe calcular el precio definitivo.'
    );

    System.assertNotEquals(
        null,
        savedRental.VRT_DIV_TotalCost__c,
        'El trigger debe calcular el precio definitivo.'
    );

    System.assert(
        savedRental.VRT_DIV_TotalCost__c > 0,
        'El precio definitivo debe ser mayor que cero.'
    );

    }

    @IsTest
static void testCreateRentalPastDate() {

    // ========= ARRANGE =========

    Account account = new Account(
        Name = 'Cliente Fecha Pasada'
    );
    insert account;

    VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
        VRT_TXT_LicensePlate__c = '9090ZZZ',
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

    Date startDate = Date.today().addDays(-1);
    Date endDate = Date.today().addDays(2);

    // ========= ACT / ASSERT =========

    try {
        VRT_CLS_RentalService.createRental(
            account.Id,
            vehicle.Id,
            startDate,
            endDate
        );

        System.assert(
            false,
            'Debe lanzar una excepción si la fecha de inicio es anterior a hoy.'
        );

    } catch (IllegalArgumentException e) {

        System.assertEquals(
            'La fecha de inicio no puede ser anterior a hoy.',
            e.getMessage()
        );
    }
}

@IsTest
static void testInvalidateApprovalWhenAmountIncreases() {

    // ARRANGE
    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_SEL_ApprovalStatus__c = 'Approved',
        Approved_Amount__c = 5000,
        VRT_DIV_TotalCost__c = 7000
    );

    // ACT
    VRT_CLS_RentalService.updateApprovalStatusForAmountChange(
        new List<VRT_Rental__c>{ rental }
    );

    // ASSERT
    System.assertEquals(
        'Not Required',
        rental.VRT_SEL_ApprovalStatus__c,
        'La aprobación debe invalidarse si el coste supera el importe aprobado.'
    );
}


@IsTest
static void testKeepApprovalWhenAmountDoesNotIncrease() {

    // ARRANGE
    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_SEL_ApprovalStatus__c = 'Approved',
        Approved_Amount__c = 5000,
        VRT_DIV_TotalCost__c = 4000
    );

    // ACT
    VRT_CLS_RentalService.updateApprovalStatusForAmountChange(
        new List<VRT_Rental__c>{ rental }
    );

    // ASSERT
    System.assertEquals(
        'Approved',
        rental.VRT_SEL_ApprovalStatus__c,
        'La aprobación debe mantenerse si el nuevo coste no supera el importe aprobado.'
    );
}

@IsTest
static void testApprovalNotRequiredWhenAmountFallsBelowThreshold() {

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_SEL_ApprovalStatus__c = 'Approved',
        Approved_Amount__c = 5000,
        VRT_DIV_TotalCost__c = 2500
    );

    VRT_CLS_RentalService.updateApprovalStatusForAmountChange(
        new List<VRT_Rental__c>{ rental }
    );

    System.assertEquals(
        'Not Required',
        rental.VRT_SEL_ApprovalStatus__c,
        'La aprobación deja de ser necesaria cuando el coste baja a 3000 euros o menos.'
    );
}

}
