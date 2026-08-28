public without sharing class VRT_CLS_ApprovalService {

    public static void updateRejectionReasons(
        Map<Id, VRT_Rental__c> oldMap,
        Map<Id, VRT_Rental__c> newMap
    ) {

        Set<Id> rejectedRentalIds = new Set<Id>();

        for (Id rentalId : newMap.keySet()) {

            VRT_Rental__c oldRental = oldMap.get(rentalId);
            VRT_Rental__c newRental = newMap.get(rentalId);

            if (
                oldRental.VRT_SEL_ApprovalStatus__c != 'Rejected' &&
                newRental.VRT_SEL_ApprovalStatus__c == 'Rejected'
            ) {
                rejectedRentalIds.add(rentalId);
            }
        }

        if (rejectedRentalIds.isEmpty()) {
            return;
        }

        List<ProcessInstanceStep> rejectedSteps = [
            SELECT
                Id,
                StepStatus,
                Comments,
                CreatedDate,
                ProcessInstance.TargetObjectId
            FROM ProcessInstanceStep
            WHERE StepStatus = 'Rejected'
            AND ProcessInstance.TargetObjectId IN :rejectedRentalIds
            ORDER BY CreatedDate DESC
        ];

        Map<Id, String> rejectionReasonByRentalId =
            new Map<Id, String>();

        for (ProcessInstanceStep step : rejectedSteps) {

            Id rentalId = step.ProcessInstance.TargetObjectId;

            if (!rejectionReasonByRentalId.containsKey(rentalId)) {
                rejectionReasonByRentalId.put(
                    rentalId,
                    step.Comments
                );
            }
        }

        List<VRT_Rental__c> rentalsToUpdate = new List<VRT_Rental__c>();

        for (Id rentalId : rejectionReasonByRentalId.keySet()) {

            String reason = rejectionReasonByRentalId.get(rentalId);

            if (String.isNotBlank(reason)) {
                rentalsToUpdate.add(
                    new VRT_Rental__c(
                        Id = rentalId,
                        VRT_TXT_Rejection_Reason__c = reason
                    )
                );
            }
        }

        if (!rentalsToUpdate.isEmpty()) {
            update rentalsToUpdate;
        }
    }
}