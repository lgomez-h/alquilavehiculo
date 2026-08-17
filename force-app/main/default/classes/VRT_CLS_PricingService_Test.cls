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
    Integer completedRentals,
    Decimal expectedPrice
)
{
    Decimal finalPrice =
        VRT_CLS_PricingService.applyLoyaltyDiscount(
            basePrice,
            completedRentals
        );

    System.assertEquals(
        expectedPrice,
        finalPrice,
        'El precio final con descuento no es el esperado.'
    );
}

@IsTest
static void testApplyLoyaltyDiscountYes() {

    verifyLoyaltyDiscount(
        200,
        3,
        190
    );
}
@IsTest
static void testApplyLoyaltyDiscountNo() {

    verifyLoyaltyDiscount(
        200,
        1,
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


private static void verifyFinalPrice(
    String vehicleType,
    Date startDate,
    Date expectedReturnDate,
    Integer completedRentals,
    Date actualReturnDate,
    Decimal expectedPrice
) {
    Decimal finalPrice =
        VRT_CLS_PricingService.calculateFinalPrice(
            vehicleType,
            startDate,
            expectedReturnDate,
            completedRentals,
            actualReturnDate
        );

    System.assertEquals(
        expectedPrice,
        finalPrice,
        'El precio final calculado no es el esperado.'
    );
}

@IsTest
static void testCalculateFinalPriceWithLoyaltyNoDelay() {
    
    verifyFinalPrice(
        'Coche',
        Date.newInstance(2026, 7, 1),
        Date.newInstance(2026, 7, 4),
        3,
        null,
        228
    );
}

@IsTest
static void testCalculateFinalPriceWithLoyaltyAndLatePenalty() {

    verifyFinalPrice(
        'Coche',
        Date.newInstance(2026, 7, 1),
        Date.newInstance(2026, 7, 4),
        3,
        Date.newInstance(2026, 7, 5),
        328
    );
}

}