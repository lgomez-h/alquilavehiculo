public with sharing class VRT_CLS_PricingService {

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
}