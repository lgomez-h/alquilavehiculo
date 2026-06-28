@IsTest
private class VRT_CLS_PricingService_Test {

    /**
     * Comprueba que una regla de precios es correcta.
     */
    private static void verifyPricingRule(
        String vehicleType,
        String season,
        Decimal expectedPrice
    ) {

        // ========= ACT =========
        // Ejecutamos el método que queremos probar.
        VRT_PricingRule__mdt rule =
            VRT_CLS_PricingService.getPricingRule(
                vehicleType,
                season
            );

        // ========= ASSERT =========

        // Debe devolver una regla.
        System.assertNotEquals(
            null,
            rule,
            'Debe encontrarse una regla para ' + vehicleType + ' en temporada ' + season
        );

        // Debe ser del vehículo esperado.
        System.assertEquals(
            vehicleType,
            rule.VRT_TXT_VehicleType__c,
            'El tipo de vehículo no es correcto.'
        );

        // Debe ser de la temporada esperada.
        System.assertEquals(
            season,
            rule.VRT_TXT_Season__c,
            'La temporada no es correcta.'
        );

        // Debe tener el precio esperado.
        System.assertEquals(
            expectedPrice,
            rule.VRT_NUM_PricePerDay__c,
            'El precio no es el esperado.'
        );
    }

    @IsTest
    static void testGetPricingRuleCarHigh() {
        verifyPricingRule('Coche', 'Alta', 80);
    }

    @IsTest
    static void testGetPricingRuleCarMedium() {
        verifyPricingRule('Coche', 'Media', 60);
    }

    @IsTest
    static void testGetPricingRuleCarLow() {
        verifyPricingRule('Coche', 'Baja', 45);
    }

    @IsTest
    static void testGetPricingRuleMotoHigh() {
        verifyPricingRule('Moto', 'Alta', 50);
    }

    @IsTest
    static void testGetPricingRuleMotoMedium() {
        verifyPricingRule('Moto', 'Media', 35);
    }

    @IsTest
    static void testGetPricingRuleMotoLow() {
        verifyPricingRule('Moto', 'Baja', 25);
    }

    private static void verifySeason(
    Date rentalDate,
    String expectedSeason
    ){
        // ========= ACT =========
        String season = VRT_CLS_PricingService.calculateSeason(rentalDate);

        // ========= ASSERT =========
        System.assertEquals(
            expectedSeason,
            season,
            'La temporada calculada no es la esperada.'
        );
    }
    @IsTest
    static void testCalculateSeasonHigh() {
    verifySeason(
        Date.newInstance(2026, 7, 15),
        'Alta'
    );
    }
    @IsTest
    static void testCalculateSeasonMedium() {
    verifySeason(
        Date.newInstance(2026, 5, 15),
        'Media'
    );
    }
    @IsTest
    static void testCalculateSeasonLow() {
    verifySeason(
        Date.newInstance(2026, 10, 15),
        'Baja'
    );
    }
    private static void verifyBasePrice(
    String vehicleType,
    Date startDate,
    Date endDate,
    Decimal expectedPrice
) {
    Decimal basePrice =
        VRT_CLS_PricingService.calculateBasePrice(
            vehicleType,
            startDate,
            endDate
        );

    System.assertEquals(
        expectedPrice,
        basePrice,
        'El precio base calculado no es el esperado.'
    );
}
@IsTest
static void testCalculateBasePriceSameSeason() {
    verifyBasePrice(
        'Coche',
        Date.newInstance(2026, 7, 1),
        Date.newInstance(2026, 7, 4),
        240
    );
}
@IsTest
static void testCalculateBasePriceCrossSeason() {
    verifyBasePrice(
        'Coche',
        Date.newInstance(2026, 8, 30),
        Date.newInstance(2026, 9, 2),
        220
    );
}
private static void verifyLoyaltyDiscount(
    Decimal basePrice,
    Id accountId,
    Decimal expectedPrice
)
{
    Decimal finalPrice =
        VRT_CLS_PricingService.applyLoyaltyDiscount(
            basePrice,
            accountId
        );

    System.assertEquals(
        expectedPrice,
        finalPrice,
        'El precio final con descuento no es el esperado.'
    );
}
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
static void testApplyLoyaltyDiscountYes() {

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    verifyLoyaltyDiscount(
        200,
        account.Id,
        190
    );
}
@IsTest
static void testApplyLoyaltyDiscountNo() {

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test 2'
        LIMIT 1
    ];

    verifyLoyaltyDiscount(
        200,
        account.Id,
        200
    );
}


private static void verifyLatePenalty(
    Decimal currentPrice,
    String vehicleType,
    Date expectedReturnDate,
    Date actualReturnDate,
    Decimal expectedPrice
    ) {
    Decimal finalPrice =
        VRT_CLS_PricingService.applyLatePenalty(
            currentPrice,
            vehicleType,
            expectedReturnDate,
            actualReturnDate
        );

    System.assertEquals(
        expectedPrice,
        finalPrice,
        'La penalización por retraso no es la esperada.'
    );
}

@IsTest
static void testApplyLatePenaltyNoDelay() {
    verifyLatePenalty(
        240,
        'Coche',
        Date.newInstance(2026, 7, 10),
        Date.newInstance(2026, 7, 10),
        240
    );
}

@IsTest
static void testApplyLatePenaltyWithDelaySameSeason() {
    verifyLatePenalty(
        240,
        'Coche',
        Date.newInstance(2026, 7, 10),
        Date.newInstance(2026, 7, 12),
        440
    );
}

@IsTest
static void testApplyLatePenaltyDifferentSeason() {

    verifyLatePenalty(
        400,
        'Coche',
        Date.newInstance(2026, 8, 30),
        Date.newInstance(2026, 9, 2),
        650
    );
}


@IsTest
static void testApplyLatePenaltyNullActualReturnDate() {
    verifyLatePenalty(
        240,
        'Coche',
        Date.newInstance(2026, 7, 10),
        null,
        240
    );
}
}