public without sharing class VRT_CLS_InvoiceFinalizer
    implements System.Finalizer {

    private Set<Id> rentalIds;

    public VRT_CLS_InvoiceFinalizer(Set<Id> rentalIds) {
        this.rentalIds = rentalIds;
    }

    public void execute(System.FinalizerContext context) {

        System.ParentJobResult result = context.getResult();

        if (result == System.ParentJobResult.SUCCESS) {
            return;
        }

        Exception jobexception = context.getException();

        String errorMessage =
            jobexception != null
                ? jobexception.getMessage()
                : 'Error desconocido durante la facturación.';

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

        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
}