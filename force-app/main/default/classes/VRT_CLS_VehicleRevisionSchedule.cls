public with sharing class VRT_CLS_VehicleRevisionSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Lanza el batch
        VRT_CLS_CheckVehicleRevision batch = new VRT_CLS_CheckVehicleRevision();
        // Puedes cambiar los valores (scope/batchSize) si quieres
        Database.executeBatch(batch, 200);
    }
}