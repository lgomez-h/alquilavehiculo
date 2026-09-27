// Clase que implementa la creación de facturas.
public without sharing class VRT_CLS_InvoiceService {

    public static void createInvoices(Set<Id> rentalIds) {

        if (rentalIds == null || rentalIds.isEmpty()) {
            return;
        }
        // Obtengo los alquileres correspondientes a los Ids proporcionados
        Map<Id, VRT_Rental__c> rentalsById = new Map<Id, VRT_Rental__c>([
            SELECT Id,
            Name,
            VRT_LKP_Account__c,
            VRT_LKP_Account__r.VRT_TXT_Email__c,
            VRT_DIV_TotalCost__c
            FROM VRT_Rental__c
            WHERE Id IN :rentalIds
            ]);
        
        Set<Id> alreadyInvoicedRentalIds = new Set<Id>();
        // Obtengo los Ids de los alquileres que ya tienen facturas creadas para evitar duplicados
        for (VRT_Invoice__c invoice : [
            SELECT Id, VRT_LKP_Rental__c
            FROM VRT_Invoice__c
            WHERE VRT_LKP_Rental__c IN :rentalIds
        ]) {
            alreadyInvoicedRentalIds.add(invoice.VRT_LKP_Rental__c);
        }
        // Listas para almacenar las facturas, registros de proceso y eventos de notificación
        List<VRT_Invoice__c> invoicesToInsert = new List<VRT_Invoice__c>();
        List<VRT_ProcessLog__c> logsToInsert = new List<VRT_ProcessLog__c>();
        List<VRT_InvoiceNotificationEvent__e> eventsToPublish = new List<VRT_InvoiceNotificationEvent__e>();
        // Itero sobre los alquileres y creo facturas para aquellos que no tienen facturas existentes
        for (VRT_Rental__c rental : rentalsById.values()) {
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

            
        }
        // Inserto las facturas creadas
        if (!invoicesToInsert.isEmpty()) {
            insert invoicesToInsert;
            // Registro de éxito y publicación de eventos para cada factura creada
            for (VRT_Invoice__c invoice : invoicesToInsert) {
            // Obtengo el alquiler correspondiente a la factura creada
            VRT_Rental__c rental = rentalsById.get(invoice.VRT_LKP_Rental__c);logsToInsert.add(new VRT_ProcessLog__c(
                VRT_LKP_Rental__c = rental.Id,
                Status__c = 'Success',
                VRT_Message__c = 'Invoice created successfully.',
                VRT_Execution_Date__c = System.now()
            ));
            // Creo un evento de notificación para cada factura creada
            eventsToPublish.add(
            new VRT_InvoiceNotificationEvent__e(
            VRT_RentalId__c = rental.Id,
            VRT_Invoice_Id__c = invoice.Id,
            VRT_AccountEmail__c = rental.VRT_LKP_Account__r.VRT_TXT_Email__c,
            VRT_Message__c = 'Invoice created successfully.'));
        }
        }
        // Publico los eventos de notificación y registro de procesos en la base de datos
        if (!eventsToPublish.isEmpty()) {
            EventBus.publish(eventsToPublish);
        }

        // Inserto los registros de proceso en la base de datos
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}

