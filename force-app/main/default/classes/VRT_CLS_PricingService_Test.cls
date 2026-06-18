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
}