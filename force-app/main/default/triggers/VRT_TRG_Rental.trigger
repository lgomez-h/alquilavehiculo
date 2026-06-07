trigger VRT_TRG_Rental on VRT_Rental__c (
    before insert,
    before update,
    after insert,
    after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            VRT_TRG_RentalHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            VRT_TRG_RentalHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            VRT_TRG_RentalHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            VRT_TRG_RentalHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}