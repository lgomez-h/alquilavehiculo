public without sharing class VRT_TRG_RentalHandlerHelper {

    // PROCESO 1 (after insert):
    // - Sumar +1 al nº de usos del vehículo relacionado
    // - Recalcular la condición del vehículo
    public static void updateConditionVehicle(
        List<VRT_Rental__c> newRentals
    ) {

        // 1) Contamos cuántos alquileres nuevos tiene cada vehículo.
        Map<Id, Integer> rentalsCountByVehicleId =
            new Map<Id, Integer>();

        for (VRT_Rental__c rental : newRentals) {

            if (rental.VRT_LKP_Vehicle__c == null) {
                continue;
            }

            Id vehicleId = rental.VRT_LKP_Vehicle__c;

            Integer currentCount =
                rentalsCountByVehicleId.containsKey(vehicleId)
                    ? rentalsCountByVehicleId.get(vehicleId)
                    : 0;

            rentalsCountByVehicleId.put(
                vehicleId,
                currentCount + 1
            );
        }

        if (rentalsCountByVehicleId.isEmpty()) {
            return;
        }

        // 2) Recuperamos todos los vehículos afectados en una sola consulta.
        Map<Id, VRT_Vehicle__c> vehiclesById =
            new Map<Id, VRT_Vehicle__c>([
                SELECT
                    Id,
                    VRT_NUM_Usage__c,
                    VRT_SEL_Condition__c
                FROM VRT_Vehicle__c
                WHERE Id IN :rentalsCountByVehicleId.keySet()
                FOR UPDATE
            ]);

        // 3) Sumamos a Usage el número real de alquileres
        // nuevos que ha recibido cada vehículo.
        List<VRT_Vehicle__c> vehiclesToUpdate =
            new List<VRT_Vehicle__c>();

        for (Id vehicleId : vehiclesById.keySet()) {

            VRT_Vehicle__c vehicle =
                vehiclesById.get(vehicleId);

            Integer usage =
                vehicle.VRT_NUM_Usage__c == null
                    ? 0
                    : Integer.valueOf(
                        vehicle.VRT_NUM_Usage__c
                    );

            Integer newRentalsCount =
                rentalsCountByVehicleId.get(vehicleId);

            usage = usage + newRentalsCount;

            vehicle.VRT_NUM_Usage__c = usage;
            vehicle.VRT_SEL_Condition__c =
                calculateCondition(usage);

            vehiclesToUpdate.add(vehicle);
        }

        // 4) Un único DML para todos los vehículos.
        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate;
        }
    }

    // PROCESO 2 (after update):
    // Si el alquiler pasa de "En curso" a "Completado", sumar kilometraje al vehículo.
    public static void updateVehicleRentalCompleted(
        Map<Id, VRT_Rental__c> oldMap,
        Map<Id, VRT_Rental__c> newMap
    ) {
        Set<Id> vehicleIds = new Set<Id>();
        Map<Id, Decimal> extraKmByVehicleId = new Map<Id, Decimal>();

        // 1) Detectamos qué alquileres cambian de estado "En curso" -> "Completado"
        for (Id rentalId : newMap.keySet()) {
            VRT_Rental__c oldR = oldMap.get(rentalId);
            VRT_Rental__c newR = newMap.get(rentalId);

            if (newR.VRT_LKP_Vehicle__c == null) continue;

            Boolean changedToCompleted =
                oldR.VRT_SEL_Status__c == 'En curso' &&
                newR.VRT_SEL_Status__c == 'Completado';

            if (!changedToCompleted) continue;

            Decimal days = (newR.VRT_FOR_Duration__c == null) ? 0 : newR.VRT_FOR_Duration__c;
            Decimal extraKm = 200 * days;

            vehicleIds.add(newR.VRT_LKP_Vehicle__c);

            Decimal current = extraKmByVehicleId.containsKey(newR.VRT_LKP_Vehicle__c)
                ? extraKmByVehicleId.get(newR.VRT_LKP_Vehicle__c)
                : 0;

            extraKmByVehicleId.put(newR.VRT_LKP_Vehicle__c, current + extraKm);
        }

        if (vehicleIds.isEmpty()) return;

        // 2) SOQL: Traemos vehículos en 1 consulta
        Map<Id, VRT_Vehicle__c> vehiclesById = new Map<Id, VRT_Vehicle__c>([
            SELECT Id, VRT_NUM_Mileage__c
            FROM VRT_Vehicle__c
            WHERE Id IN :vehicleIds
            FOR UPDATE
        ]);

        // 3) Sumamos kilometraje y guardamos
        List<VRT_Vehicle__c> vehiclesToUpdate = new List<VRT_Vehicle__c>();
        for (Id vid : vehiclesById.keySet()) {
            VRT_Vehicle__c v = vehiclesById.get(vid);

            Decimal currentMileage = (v.VRT_NUM_Mileage__c == null) ? 0 : v.VRT_NUM_Mileage__c;
            Decimal extraKm = extraKmByVehicleId.get(vid);

            v.VRT_NUM_Mileage__c = currentMileage + extraKm;
            vehiclesToUpdate.add(v);
        }

        if (!vehiclesToUpdate.isEmpty()) {
            update vehiclesToUpdate;
        }
    }

    // Función de apoyo: convierte Nº usos -> texto de condición
    private static String calculateCondition(Integer uses) {
        if (uses == null) uses = 0;

        if (uses <= 50) return 'Recién fabricado';
        if (uses <= 200) return 'Casi nuevo';
        if (uses <= 500) return 'Algo desgastado';
        if (uses <= 1000) return 'Bastante desgastado';
        return 'Deplorable';
    }
    public static void setActualReturnDateWhenCompleted(
    Map<Id, VRT_Rental__c> oldMap,
    Map<Id, VRT_Rental__c> newMap
) {
    for (Id rentalId : newMap.keySet()) {
        VRT_Rental__c oldR = oldMap.get(rentalId);
        VRT_Rental__c newR = newMap.get(rentalId);

        Boolean changedToCompleted =
            oldR.VRT_SEL_Status__c != 'Completado' &&
            newR.VRT_SEL_Status__c == 'Completado';
        // Compruebo si la fecha de devolución real está vacía
        Boolean actualReturnDateIsEmpty =
            newR.VRT_DAT_ActualReturnDate__c == null;

        if (changedToCompleted && actualReturnDateIsEmpty) {
            newR.VRT_DAT_ActualReturnDate__c = Date.today();
        }
    }
}
}