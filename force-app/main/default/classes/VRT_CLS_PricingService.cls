public with sharing class VRT_CLS_PricingService {

    private static final Integer LOYALTY_RENTALS = 3;
    private static final Decimal LOYALTY_DISCOUNT = 0.05;
    
    private static Map<String, VRT_PricingRule__mdt> pricingRules;

    public static VRT_PricingRule__mdt getPricingRule(
        String vehicleType,
        String season
    ) {
        // Cargar las reglas de precios si aún no se han cargado
        if (pricingRules == null) {
            loadPricingRules();
        }
        // si ya esta cargado, busco la regla de precios en el mapa
        String key = buildKey(vehicleType, season);

        return pricingRules.get(key);
    }

    private static void loadPricingRules() {
        pricingRules = new Map<String, VRT_PricingRule__mdt>();
        // Cargo todas las reglas activas de precios en el mapa
        for (VRT_PricingRule__mdt rule : VRT_PricingRule__mdt.getAll().values()) {
            if (rule.VRT_FLG_Active__c) {
                // Construyo una buildkey por cada regla
                String key = buildKey(
                    rule.VRT_TXT_VehicleType__c,
                    rule.VRT_TXT_Season__c
                );
                // Coloco en el map la clave y la regla de precios
                pricingRules.put(key, rule);
            }
        }
    }

    // Construye una clave a partir del tipo de vehículo y la temporada
    private static String buildKey(
        String vehicleType,
        String season
    ) {
        return vehicleType + '_' + season;
    }
    // Calcula la temporada según el mes de la fecha de alquiler
    public static String calculateSeason(Date rentalDate) {
        Integer monthNumber = rentalDate.month();
       if (monthNumber == 1 ||
            monthNumber == 4 ||
            monthNumber == 7 || 
            monthNumber == 8 ||
            monthNumber == 12) {
        return 'Alta';
        } else if (monthNumber == 2 ||
            monthNumber == 5 ||
            monthNumber == 6 ||
            monthNumber == 9 ) {
            return 'Media';
        } else {
            return 'Baja';
        }
    }
    // calcula el precio base del alquiler
    public static Decimal calculateBasePrice(
    String vehicleType,
    Date startDate,
    Date endDate
    ) {
        Date currentDate = startDate;
        Decimal totalPrice = 0;
        while (currentDate < endDate) {
            // Calcular la temporada para la fecha actual
            String season = calculateSeason(currentDate);
            //busco la tarifa en mdt
            VRT_PricingRule__mdt rule =
                getPricingRule(vehicleType, season);

                if (rule == null) {
                    throw new IllegalArgumentException(
                    'No existe una tarifa configurada para el vehículo "' +
                    vehicleType +
                    '" en temporada "' +
                    season +
                    '".'
                    );
            }
            // Sumo el precio por día de la regla al total
            totalPrice += rule.VRT_NUM_PricePerDay__c;

            currentDate = currentDate.addDays(1);
        }

    return totalPrice;
}
    // Aplica un descuento por fidelidad si corresponde
    public static Decimal applyLoyaltyDiscount(
        Decimal basePrice,
        Integer completedRentals
    ) {
         if (completedRentals >= LOYALTY_RENTALS) {
            return basePrice - (basePrice * LOYALTY_DISCOUNT);
        }

        return basePrice;
    }
    // Aplica una penalización por devolución tardía si corresponde
    public static Decimal applyLatePenalty(
    Decimal currentPrice,
    String vehicleType,
    Date expectedReturnDate,
    Date actualReturnDate
    ) {
    if (
        actualReturnDate == null ||
        actualReturnDate <= expectedReturnDate
    ) {
        return currentPrice;
    }

    Decimal finalPrice = currentPrice;
    // Calcular la penalización por cada día de retraso
    Date currentDate = expectedReturnDate.addDays(1);

    while (currentDate <= actualReturnDate) {
        String season = calculateSeason(currentDate);

        VRT_PricingRule__mdt rule =
            getPricingRule(vehicleType, season);

        if (rule == null) {
            throw new IllegalArgumentException(
                'No existe una tarifa configurada para el vehículo "' +
                vehicleType +
                '" en temporada "' +
                season +
                '".'
            );
        }

        Decimal dailyPrice = rule.VRT_NUM_PricePerDay__c;
        // Aplico un recargo del 25% por cada día de retraso
        finalPrice += dailyPrice;
        finalPrice += dailyPrice * 0.25;

        currentDate = currentDate.addDays(1);
    }

    return finalPrice;
    }

    //calcula el precio final del alquiler

    public static Decimal calculateFinalPrice(
    String vehicleType,
    Date startDate,
    Date expectedReturnDate,
    Integer completedRentals,
    Date actualReturnDate
    ) {
    // Calcular el precio base del alquiler
    Decimal finalPrice =
        calculateBasePrice(
            vehicleType,
            startDate,
            expectedReturnDate
        );
    // Aplicar el descuento por fidelidad si corresponde
    finalPrice =
        applyLoyaltyDiscount(
            finalPrice,
            completedRentals
        );
    // Aplicar la penalización por devolución tardía si correspondefinal
    finalPrice =
        applyLatePenalty(                                                                           
            finalPrice,
            vehicleType,
            expectedReturnDate,
            actualReturnDate
        );

    return finalPrice;
    }
}