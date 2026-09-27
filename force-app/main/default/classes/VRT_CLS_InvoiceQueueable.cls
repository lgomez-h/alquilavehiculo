// Clase que implementa la interfaz Queueable para crear facturas de forma asincrónica.

public with sharing class VRT_CLS_InvoiceQueueable implements Queueable {

    private Set<Id> rentalIds;
    // Constructor que recibe un conjunto de Ids de alquileres para los cuales se crearán facturas.
    public VRT_CLS_InvoiceQueueable(Set<Id> rentalIds) {
        this.rentalIds = rentalIds;
    }
    // Método execute que se ejecuta cuando se procesa el trabajo en cola.
    public void execute(QueueableContext context) {
        // Se adjunta un finalizador para manejar la finalización del trabajo en cola.
        System.attachFinalizer(
            new VRT_CLS_InvoiceFinalizer(rentalIds)
        );
        // Llamada al servicio de facturación para crear facturas para los alquileres proporcionados.
        VRT_CLS_InvoiceService.createInvoices(rentalIds);
    }
}