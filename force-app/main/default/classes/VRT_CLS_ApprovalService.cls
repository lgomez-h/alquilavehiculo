public without sharing class VRT_CLS_ApprovalService {

    public static void updateRejectionReasons(
        Map<Id, VRT_Rental__c> oldMap,
        Map<Id, VRT_Rental__c> newMap
    ) {
        // Recojo en un Set los Ids de los alquileres que han sido rechazados
        Set<Id> rejectedRentalIds = new Set<Id>();

        for (Id rentalId : newMap.keySet()) {
            // Compruebo si el estado de aprobación ha cambiado de no rechazado a rechazado
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
        // Consulto los pasos de aprobación rechazados para estos alquileres
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
        // Creo un mapa para almacenar la razón de rechazo más reciente para cada alquiler
        Map<Id, String> rejectionReasonByRentalId =
            new Map<Id, String>();

        for (ProcessInstanceStep step : rejectedSteps) {

            Id rentalId = step.ProcessInstance.TargetObjectId;
            // Si aún no he registrado una razón de rechazo para este alquiler, la agrego al mapa
            if (!rejectionReasonByRentalId.containsKey(rentalId)) {
                rejectionReasonByRentalId.put(
                    rentalId,
                    step.Comments
                );
            }
        }
        // actualizo el campo de razón de rechazo en los alquileres rechazados
        List<VRT_Rental__c> rentalsToUpdate = new List<VRT_Rental__c>();

        for (Id rentalId : rejectionReasonByRentalId.keySet()) {
            // Obtengo la razón de rechazo más reciente para este alquiler
            String reason = rejectionReasonByRentalId.get(rentalId);
            // Si la razón de rechazo no está vacía, creo un registro de alquiler para actualizar el campo de razón de rechazo
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