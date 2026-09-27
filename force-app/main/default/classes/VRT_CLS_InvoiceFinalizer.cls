public without sharing class VRT_CLS_InvoiceFinalizer
    implements System.Finalizer {

    private Set<Id> rentalIds;
        // Constructor que recibe un conjunto de Ids de alquileres para los cuales se crearán facturas.
    public VRT_CLS_InvoiceFinalizer(Set<Id> rentalIds) {
        this.rentalIds = rentalIds;
    }
    // Método execute que se ejecuta cuando se procesa el trabajo en cola.
    public void execute(System.FinalizerContext context) {
        // Obtengo el resultado del trabajo en cola
        System.ParentJobResult result = context.getResult();

        if (result == System.ParentJobResult.SUCCESS) {
            return;
        }
        // Si el trabajo en cola falló, obtengo la excepción y registro un mensaje de error en un objeto de registro de proceso personalizado
        Exception jobexception = context.getException();

        String errorMessage =
            jobexception != null
                ? jobexception.getMessage()
                : 'Error desconocido durante la facturación.';
        // Registrar el error para cada alquiler afectado
        List<VRT_ProcessLog__c> errorLogs =
            new List<VRT_ProcessLog__c>();
            
        for (Id rentalId : rentalIds) {
            errorLogs.add(new VRT_ProcessLog__c(
                VRT_LKP_Rental__c = rentalId,
                Status__c = 'Error',
                VRT_Message__c = errorMessage,
                VRT_Execution_Date__c = System.now()
            ));
        }
        // Insertar los registros de error en la base de datos
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
}