public with sharing class VRT_CLS_InvoiceQueueable implements Queueable {

    private List<VRT_Rental__c> rentals;

    public VRT_CLS_InvoiceQueueable(List<VRT_Rental__c> rentals) {
        this.rentals = rentals;
    }

    public void execute(QueueableContext context) {
        VRT_CLS_InvoiceService.createInvoices(rentals);
    }
}