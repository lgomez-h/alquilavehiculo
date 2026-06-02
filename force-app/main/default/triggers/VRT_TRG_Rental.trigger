trigger VRT_TRG_Rental on VRT_Rental__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            VRT_TRG_RentalHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            VRT_TRG_RentalHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}