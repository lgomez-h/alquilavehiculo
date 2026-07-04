public with sharing class VRT_CLS_InvoiceService {

    public static void createInvoices(List<VRT_Rental__c> rentals) {
        if (rentals == null || rentals.isEmpty()) {
            return;
        }

        Set<Id> rentalIds = new Set<Id>();

        for (VRT_Rental__c rental : rentals) {
            if (rental.Id != null) {
                rentalIds.add(rental.Id);
            }
        }

        if (rentalIds.isEmpty()) {
            return;
        }

        Set<Id> alreadyInvoicedRentalIds = new Set<Id>();

        for (VRT_Invoice__c invoice : [
            SELECT Id, VRT_LKP_Rental__c
            FROM VRT_Invoice__c
            WHERE VRT_LKP_Rental__c IN :rentalIds
        ]) {
            alreadyInvoicedRentalIds.add(invoice.VRT_LKP_Rental__c);
        }

        List<VRT_Invoice__c> invoicesToInsert = new List<VRT_Invoice__c>();
        List<VRT_ProcessLog__c> logsToInsert = new List<VRT_ProcessLog__c>();

        for (VRT_Rental__c rental : rentals) {
           if (alreadyInvoicedRentalIds.contains(rental.Id)) {
                logsToInsert.add(new VRT_ProcessLog__c(
                VRT_LKP_Rental__c = rental.Id,
                Status__c = 'Duplicate',
                VRT_Message__c = 'Invoice already exists. No duplicate invoice was created.',
                VRT_Execution_Date__c = System.now()
                ));

                continue;
            }

            invoicesToInsert.add(new VRT_Invoice__c(
                VRT_LKP_Rental__c = rental.Id,
                VRT_LKP_Account__c = rental.VRT_LKP_Account__c,
                VRT_CUR_TotalAmount__c = rental.VRT_DIV_TotalCost__c,
                VRT_DAT_IssueDate__c = Date.today(),
                VRT_SEL_Status__c = 'Emitida'
            ));

            logsToInsert.add(new VRT_ProcessLog__c(
                VRT_LKP_Rental__c = rental.Id,
                Status__c = 'Success',
                VRT_Message__c = 'Invoice created successfully.',
                VRT_Execution_Date__c = System.now()
            ));
        }

    try {

        if (!invoicesToInsert.isEmpty()) {
            insert invoicesToInsert;
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    
    } catch (Exception e) {

    List<VRT_ProcessLog__c> errorLogs = new List<VRT_ProcessLog__c>();

    for (VRT_Rental__c rental : rentals) {
            
            errorLogs.add(new VRT_ProcessLog__c(
            VRT_LKP_Rental__c = rental.Id,
            Status__c = 'Error',
            VRT_Message__c = e.getMessage(),
            VRT_Execution_Date__c = System.now()
            ));
        }

        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }

        throw e;
        }
    }
}