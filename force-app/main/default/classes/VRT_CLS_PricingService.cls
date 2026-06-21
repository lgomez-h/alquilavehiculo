public with sharing class VRT_CLS_PricingService {

    private static final Integer LOYALTY_RENTALS = 3;
    private static final Decimal LOYALTY_DISCOUNT = 0.05;
    
    private static Map<String, VRT_PricingRule__mdt> pricingRules;

    public static VRT_PricingRule__mdt getPricingRule(
        String vehicleType,
        String season
    ) {
        if (pricingRules == null) {
            loadPricingRules();
        }

        String key = buildKey(vehicleType, season);

        return pricingRules.get(key);
    }

    private static void loadPricingRules() {
        pricingRules = new Map<String, VRT_PricingRule__mdt>();

        for (VRT_PricingRule__mdt rule : VRT_PricingRule__mdt.getAll().values()) {
            if (rule.VRT_FLG_Active__c) {
                String key = buildKey(
                    rule.VRT_TXT_VehicleType__c,
                    rule.VRT_TXT_Season__c
                );

                pricingRules.put(key, rule);
            }
        }
    }

    private static String buildKey(
        String vehicleType,
        String season
    ) {
        return vehicleType + '_' + season;
    }

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

    public static Decimal calculateBasePrice(
    String vehicleType,
    Date startDate,
    Date endDate
    ) {
        Date currentDate = startDate;
        Decimal totalPrice = 0;

        while (currentDate < endDate) {
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

            totalPrice += rule.VRT_NUM_PricePerDay__c;

            currentDate = currentDate.addDays(1);
        }

    return totalPrice;
}

    public static Decimal applyLoyaltyDiscount(
        Decimal basePrice,
        Id accountId
    ) {

        Integer completedRentals =
            VRT_CLS_RentalService.countCompletedRentalsLast12Months(
                accountId
         );

        if (completedRentals >= LOYALTY_RENTALS) {
            return basePrice - (basePrice * LOYALTY_DISCOUNT);
        }

        return basePrice;
    }
}