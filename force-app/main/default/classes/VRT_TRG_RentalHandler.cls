public with sharing class VRT_TRG_RentalHandler {
    
    public static void onAfterInsert(List<VRT_Rental__c> newRentals) {
        VRT_TRG_RentalHandlerHelper.updateConditionVehicle(newRentals);
    }        
    public static void onAfterUpdate(Map<Id, VRT_Rental__c> oldMap,Map<Id, VRT_Rental__c> newMap) {
        VRT_TRG_RentalHandlerHelper.updateVehicleRentalCompleted(oldMap, newMap);
    }
    public static void onBeforeInsert(List<VRT_Rental__c> newRentals) {
    }

    public static void onBeforeUpdate(
        Map<Id,VRT_Rental__c> oldMap,
        Map<Id,VRT_Rental__c> newMap) 
    {

}
}