public without sharing class VRT_CLS_CheckVehicleRevision implements Database.Batchable<SObject> {

    // Método que inicia el batch
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Busca todos los vehículos cuyo flag está en FALSE
        return Database.getQueryLocator([
            SELECT Id, VRT_DAT_ManufacturedYear__c, VRT_SEL_VehicleType__c, VRT_FLG_NeedsInspection__c
            FROM VRT_Vehicle__c
            WHERE VRT_FLG_NeedsInspection__c = FALSE
        ]);
    }

    // Ejecuta la lógica procesando grupos de vehículos 
    public void execute(Database.BatchableContext BC, List<VRT_Vehicle__c> vehicles) {
        Integer thisYear = Date.today().year();

        List<VRT_Vehicle__c> toUpdate = new List<VRT_Vehicle__c>();
        for (VRT_Vehicle__c v : vehicles) {
            if (v.VRT_DAT_ManufacturedYear__c == null || v.VRT_SEL_VehicleType__c == null) continue;

            // Calcula la edad del vehículo
            Integer vehicleAge = thisYear - v.VRT_DAT_ManufacturedYear__c.year();

            Boolean needsInspection = false;
            // Si coche y >=4 años
            if (v.VRT_SEL_VehicleType__c == 'Coche' && vehicleAge >= 4) {
                needsInspection = true;
            }
            // Si moto y >=3 años
            if (v.VRT_SEL_VehicleType__c == 'Moto' && vehicleAge >= 3) {
                needsInspection = true;
            }

            if (needsInspection) {
                v.VRT_FLG_NeedsInspection__c = true;
                toUpdate.add(v);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // Al final puede enviar notificaciones o logs, aquí simplemente nada.
    public void finish(Database.BatchableContext BC) {
        // Nada por ahora, puedes poner debug/log/etc.
    }
}