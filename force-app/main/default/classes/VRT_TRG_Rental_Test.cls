@IsTest
public with sharing class VRT_TRG_Rental_Test {

    @testSetup
    static void setup() {
        // (No siempre hace falta Account, pero lo dejamos si tu org lo requiere en algún flujo)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Vehículos con required fields + matrícula 7 caracteres + estado "Listo"
        List<VRT_Vehicle__c> vehicles = new List<VRT_Vehicle__c>{
            new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '1234ABC',
                VRT_TXT_Brand__c = 'Toyota',
                VRT_SEL_VehicleType__c = 'Coche',
                VRT_SEL_Status__c = 'Listo',
                VRT_SEL_EnergyType__c = 'Gasolina',
                VRT_NUM_Passengers__c = 5,
                VRT_FLG_Available__c = true,
                VRT_NUM_Usage__c = 0,
                VRT_NUM_Mileage__c = 0
            ),
            new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '2345BCD',
                VRT_TXT_Brand__c = 'Seat',
                VRT_SEL_VehicleType__c = 'Coche',
                VRT_SEL_Status__c = 'Listo',
                VRT_SEL_EnergyType__c = 'Gasolina',
                VRT_NUM_Passengers__c = 5,
                VRT_FLG_Available__c = true,
                VRT_NUM_Usage__c = 60,
                VRT_NUM_Mileage__c = 0
            ),
            new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '3456CDE',
                VRT_TXT_Brand__c = 'Renault',
                VRT_SEL_VehicleType__c = 'Coche',
                VRT_SEL_Status__c = 'Listo',
                VRT_SEL_EnergyType__c = 'Diesel',
                VRT_NUM_Passengers__c = 5,
                VRT_FLG_Available__c = true,
                VRT_NUM_Usage__c = 250,
                VRT_NUM_Mileage__c = 0
            ),
            new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '4567DEF',
                VRT_TXT_Brand__c = 'Honda',
                VRT_SEL_VehicleType__c = 'Coche',
                VRT_SEL_Status__c = 'Listo',
                VRT_SEL_EnergyType__c = 'Híbrido',
                VRT_NUM_Passengers__c = 5,
                VRT_FLG_Available__c = true,
                VRT_NUM_Usage__c = 700,
                VRT_NUM_Mileage__c = 0
            ),
            new VRT_Vehicle__c(
                VRT_TXT_LicensePlate__c = '5678EFG',
                VRT_TXT_Brand__c = 'Yamaha',
                VRT_SEL_VehicleType__c = 'Moto',
                VRT_SEL_Status__c = 'En mantenimiento',
                VRT_SEL_EnergyType__c = 'Gasolina',
                VRT_NUM_Passengers__c = 2,
                VRT_FLG_Available__c = true,
                VRT_NUM_Usage__c = 1200,
                VRT_NUM_Mileage__c = 0
            )
        };
        insert vehicles;
    }

    // Recupera un vehículo por sus usos iniciales (como lo definimos en testSetup)
    private static VRT_Vehicle__c getVehicleByUsage(Integer usage) {
        return [
            SELECT Id, VRT_NUM_Usage__c, VRT_SEL_Condition__c, VRT_NUM_Mileage__c
            FROM VRT_Vehicle__c
            WHERE VRT_NUM_Usage__c = :usage
            LIMIT 1
        ];
    }

    // Crea un alquiler válido según tus Validation Rules:
    // - Pago Pagado
    // - Fechas futuras y coherentes (ini <= fin)
    private static VRT_Rental__c buildValidPaidRental(Id vehicleId, String rentalStatus, Date ini, Date fin) {
        return new VRT_Rental__c(
            VRT_LKP_Vehicle__c = vehicleId,
            VRT_SEL_Status__c = rentalStatus,
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = ini,
            VRT_DAT_FinalDate__c   = fin
        );
    }

    // -----------------------
    // TESTS: condición vehículo (after insert)
    // -----------------------

    @IsTest
    static void testUpdateConditionVehicleRecienFabricado() {
        VRT_Vehicle__c v = getVehicleByUsage(0);

        Date ini = Date.today().addDays(10);
        Date fin = Date.today().addDays(11); // 1 día

        Test.startTest();
        insert buildValidPaidRental(v.Id, 'Reservado', ini, fin);
        Test.stopTest();

        VRT_Vehicle__c updated = [
            SELECT VRT_NUM_Usage__c, VRT_SEL_Condition__c
            FROM VRT_Vehicle__c
            WHERE Id = :v.Id
        ];
        System.assertEquals(1, Integer.valueOf(updated.VRT_NUM_Usage__c), 'Debe sumar 1 uso.');
        System.assertEquals('Recién fabricado', updated.VRT_SEL_Condition__c);
    }

    @IsTest
    static void testUpdateConditionVehicleCasiNuevo() {
        VRT_Vehicle__c v = getVehicleByUsage(60);

        Date ini = Date.today().addDays(12);
        Date fin = Date.today().addDays(13);

        Test.startTest();
        insert buildValidPaidRental(v.Id, 'Reservado', ini, fin);
        Test.stopTest();

        VRT_Vehicle__c updated = [SELECT VRT_SEL_Condition__c FROM VRT_Vehicle__c WHERE Id = :v.Id];
        System.assertEquals('Casi nuevo', updated.VRT_SEL_Condition__c);
    }

    @IsTest
    static void testUpdateConditionVehicleAlgoDesgastado() {
        VRT_Vehicle__c v = getVehicleByUsage(250);

        Date ini = Date.today().addDays(14);
        Date fin = Date.today().addDays(15);

        Test.startTest();
        insert buildValidPaidRental(v.Id, 'Reservado', ini, fin);
        Test.stopTest();

        VRT_Vehicle__c updated = [SELECT VRT_SEL_Condition__c FROM VRT_Vehicle__c WHERE Id = :v.Id];
        System.assertEquals('Algo desgastado', updated.VRT_SEL_Condition__c);
    }

    @IsTest
    static void testUpdateConditionVehicleBastanteDesgastado() {
        VRT_Vehicle__c v = getVehicleByUsage(700);

        Date ini = Date.today().addDays(16);
        Date fin = Date.today().addDays(17);

        Test.startTest();
        insert buildValidPaidRental(v.Id, 'Reservado', ini, fin);
        Test.stopTest();

        VRT_Vehicle__c updated = [SELECT VRT_SEL_Condition__c FROM VRT_Vehicle__c WHERE Id = :v.Id];
        System.assertEquals('Bastante desgastado', updated.VRT_SEL_Condition__c);
    }

    @IsTest
    static void testUpdateConditionVehicleDeplorable() {
        VRT_Vehicle__c v = getVehicleByUsage(1200);

        Date ini = Date.today().addDays(18);
        Date fin = Date.today().addDays(19);

        Test.startTest();
        insert buildValidPaidRental(v.Id, 'Reservado', ini, fin);
        Test.stopTest();

        VRT_Vehicle__c updated = [SELECT VRT_SEL_Condition__c FROM VRT_Vehicle__c WHERE Id = :v.Id];
        System.assertEquals('Deplorable', updated.VRT_SEL_Condition__c);
    }

    // -----------------------
    // TEST: kilometraje (after update)
    // -----------------------
    @IsTest
    static void testUpdateVehicleRentalCompleted() {
        VRT_Vehicle__c v = getVehicleByUsage(0);

        Date ini = Date.today().addDays(20);
        Date fin = ini.addDays(3); // 3 días -> 600km

        VRT_Rental__c rental = buildValidPaidRental(v.Id, 'En curso', ini, fin);
        insert rental;

        Test.startTest();
        rental.VRT_SEL_Status__c = 'Completado';
        update rental;
        Test.stopTest();

        VRT_Vehicle__c updated = [SELECT VRT_NUM_Mileage__c FROM VRT_Vehicle__c WHERE Id = :v.Id];
        System.assertEquals(600, updated.VRT_NUM_Mileage__c, '200 * 3 = 600');
    }

    @IsTest
    static void testSetActualReturnDateWhenCompleted() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = [
        SELECT Id
        FROM VRT_Vehicle__c
        LIMIT 1
    ];

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'En curso',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today(),
        VRT_DAT_FinalDate__c = Date.today().addDays(3)
    );
    insert rental;

    // ========= ACT =========

    rental.VRT_SEL_Status__c = 'Completado';
    update rental;

    // ========= ASSERT =========

    VRT_Rental__c updatedRental = [
        SELECT VRT_DAT_ActualReturnDate__c
        FROM VRT_Rental__c
        WHERE Id = :rental.Id
    ];

    System.assertNotEquals(
    null,
    updatedRental.VRT_DAT_ActualReturnDate__c,
    'La fecha real de devolución debería haberse rellenado.'
    );

    System.assertEquals(
    Date.today(),
    updatedRental.VRT_DAT_ActualReturnDate__c,
    'La fecha real de devolución debería ser la fecha de hoy.'
    );
}

@IsTest
static void testDoNotOverwriteActualReturnDateWhenCompleted() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = [
        SELECT Id
        FROM VRT_Vehicle__c
        LIMIT 1
    ];

    Date originalReturnDate = Date.today().addDays(-2);

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'En curso',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addDays(-5),
        VRT_DAT_FinalDate__c = Date.today(),
        VRT_DAT_ActualReturnDate__c = originalReturnDate
    );

    insert rental;

    // ========= ACT =========

    rental.VRT_SEL_Status__c = 'Completado';

    update rental;

    // ========= ASSERT =========

    VRT_Rental__c updatedRental = [
        SELECT VRT_DAT_ActualReturnDate__c
        FROM VRT_Rental__c
        WHERE Id = :rental.Id
    ];

    System.assertEquals(
        originalReturnDate,
        updatedRental.VRT_DAT_ActualReturnDate__c,
        'La fecha real de devolución no debería sobrescribirse.'
    );
}

@IsTest
static void testCalculateTotalCostOnInsert() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = [
        SELECT Id
        FROM VRT_Vehicle__c
        WHERE VRT_SEL_VehicleType__c = 'Coche'
        LIMIT 1
    ];

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.newInstance(2026, 7, 1),
        VRT_DAT_FinalDate__c = Date.newInstance(2026, 7, 4)
    );

    // ========= ACT =========

    insert rental;

    // ========= ASSERT =========

    VRT_Rental__c insertedRental = [
        SELECT VRT_DIV_TotalCost__c
        FROM VRT_Rental__c
        WHERE Id = :rental.Id
    ];

    System.assertEquals(
        240,
        insertedRental.VRT_DIV_TotalCost__c,
        'El coste total debería calcularse automáticamente al insertar el alquiler.'
    );
    }

    @IsTest
static void testRecalculateTotalCostOnUpdate() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = [
        SELECT Id
        FROM VRT_Vehicle__c
        WHERE VRT_SEL_VehicleType__c = 'Coche'
        LIMIT 1
    ];

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'Reservado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.newInstance(2026, 7, 1),
        VRT_DAT_FinalDate__c = Date.newInstance(2026, 7, 4)
    );

    insert rental;

    // ========= ACT =========

    rental.VRT_DAT_FinalDate__c = Date.newInstance(2026, 7, 6);

    update rental;

    // ========= ASSERT =========

    VRT_Rental__c updatedRental = [
        SELECT VRT_DIV_TotalCost__c
        FROM VRT_Rental__c
        WHERE Id = :rental.Id
    ];

    System.assertEquals(
        400,
        updatedRental.VRT_DIV_TotalCost__c,
        'El coste total debería recalcularse automáticamente al actualizar el alquiler.'
    );
}

@IsTest
static void testRecalculateTotalCostWithLatePenaltyOnCompleted() {

    // ========= ARRANGE =========

    Account account = [
        SELECT Id
        FROM Account
        LIMIT 1
    ];

    VRT_Vehicle__c vehicle = [
        SELECT Id, VRT_SEL_VehicleType__c
        FROM VRT_Vehicle__c
        WHERE VRT_SEL_VehicleType__c = 'Coche'
        LIMIT 1
    ];

    Date startDate = Date.today().addDays(-5);
    Date finalDate = Date.today().addDays(-2);

    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_LKP_Vehicle__c = vehicle.Id,
        VRT_SEL_Status__c = 'En curso',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = startDate,
        VRT_DAT_FinalDate__c = finalDate
    );

    insert rental;

    // ========= ACT =========

    rental.VRT_SEL_Status__c = 'Completado';

    update rental;

    // ========= ASSERT =========

    VRT_Rental__c updatedRental = [
        SELECT VRT_DIV_TotalCost__c,
               VRT_DAT_ActualReturnDate__c
        FROM VRT_Rental__c
        WHERE Id = :rental.Id
    ];

    String season =
        VRT_CLS_PricingService.calculateSeason(Date.today());

    Decimal dailyPrice;

    if (season == 'Alta') {
        dailyPrice = 80;
    } else if (season == 'Media') {
        dailyPrice = 60;
    } else {
        dailyPrice = 40;
    }

    Decimal expectedPrice =
        (3 * dailyPrice) +
        (2 * dailyPrice * 1.25);

    System.assertEquals(
        Date.today(),
        updatedRental.VRT_DAT_ActualReturnDate__c,
        'La fecha real de devolución debería haberse rellenado.'
    );

    System.assertEquals(
        expectedPrice,
        updatedRental.VRT_DIV_TotalCost__c,
        'El coste total debería incluir la penalización por retraso.'
    );
}

}