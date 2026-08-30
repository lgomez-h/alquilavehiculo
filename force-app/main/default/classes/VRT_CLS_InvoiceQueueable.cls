public with sharing class VRT_CLS_InvoiceQueueable implements Queueable {

    private Set<Id> rentalIds;

    public VRT_CLS_InvoiceQueueable(Set<Id> rentalIds) {
        this.rentalIds = rentalIds;
    }
    public void execute(QueueableContext context) {
        
        System.attachFinalizer(
            new VRT_CLS_InvoiceFinalizer(rentalIds)
        );

        VRT_CLS_InvoiceService.createInvoices(rentalIds);
    }
}