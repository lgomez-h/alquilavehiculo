@IsTest
private class VRT_CLS_InvoiceQueueable_Test {

    private static VRT_Vehicle__c createVehicle(String licensePlate) {
        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = licensePlate,
            VRT_TXT_Brand__c = 'Toyota',
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_SEL_Status__c = 'Listo',
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_NUM_Passengers__c = 5,
            VRT_FLG_Available__c = true,
            VRT_NUM_Usage__c = 0,
            VRT_NUM_Mileage__c = 0
        );

        insert vehicle;
        return vehicle;
    }

    private static VRT_Rental__c createRental(Id accountId, Id vehicleId) {
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = accountId,
            VRT_LKP_Vehicle__c = vehicleId,
            VRT_SEL_Status__c = 'En curso',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today(),
            VRT_DAT_FinalDate__c = Date.today().addDays(1)
        );

        insert rental;

        return [
            SELECT Id,
                   VRT_LKP_Account__c,
                   VRT_DIV_TotalCost__c,
                   VRT_SEL_Status__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];
    }

    @IsTest
    static void testCreateInvoiceWhenRentalIsCompleted() {
        Account account = new Account(Name = 'Cliente Factura Test');
        insert account;

        VRT_Vehicle__c vehicle = createVehicle('1111AAA');

        VRT_Rental__c rental = createRental(account.Id, vehicle.Id);

        Test.startTest();

        rental.VRT_SEL_Status__c = 'Completado';
        update rental;

        Test.stopTest();

        List<VRT_Invoice__c> invoices = [
            SELECT Id,
                   VRT_LKP_Rental__c,
                   VRT_LKP_Account__c,
                   VRT_CUR_TotalAmount__c,
                   VRT_SEL_Status__c
            FROM VRT_Invoice__c
            WHERE VRT_LKP_Rental__c = :rental.Id
        ];

        System.assertEquals(
            1,
            invoices.size(),
            'Debe crearse una factura al completar el alquiler.'
        );

        System.assertEquals(
            account.Id,
            invoices[0].VRT_LKP_Account__c,
            'La factura debe quedar asociada a la cuenta del alquiler.'
        );

        System.assertEquals(
            rental.VRT_DIV_TotalCost__c,
            invoices[0].VRT_CUR_TotalAmount__c,
            'La factura debe copiar el coste total del alquiler.'
        );

        System.assertEquals(
            'Emitida',
            invoices[0].VRT_SEL_Status__c,
            'La factura debe crearse en estado Emitida.'
        );
    }

    @IsTest
    static void testDoesNotCreateDuplicateInvoice() {
        Account account = new Account(Name = 'Cliente Factura Duplicada Test');
        insert account;

        VRT_Vehicle__c vehicle = createVehicle('2222BBB');

        VRT_Rental__c rental = createRental(account.Id, vehicle.Id);

        Test.startTest();

        rental.VRT_SEL_Status__c = 'Completado';
        update rental;

        Test.stopTest();

        VRT_CLS_InvoiceService.createInvoices(
            new Set<Id>{ rental.Id }
        );

        Integer invoiceCount = [
            SELECT COUNT()
            FROM VRT_Invoice__c
            WHERE VRT_LKP_Rental__c = :rental.Id
        ];

        System.assertEquals(
            1,
            invoiceCount,
            'No debe crearse una factura duplicada para el mismo alquiler.'
        );
    }

    @IsTest
    static void testBulkInvoiceCreation() {
        Account account = new Account(Name = 'Cliente Factura Bulk Test');
        insert account;

        VRT_Vehicle__c vehicle1 = createVehicle('3333CCC');
        VRT_Vehicle__c vehicle2 = createVehicle('4444DDD');

        VRT_Rental__c rental1 = createRental(account.Id, vehicle1.Id);
        VRT_Rental__c rental2 = createRental(account.Id, vehicle2.Id);

        rental1.VRT_SEL_Status__c = 'Completado';
        rental2.VRT_SEL_Status__c = 'Completado';

        Test.startTest();

        update new List<VRT_Rental__c>{ rental1, rental2 };

        Test.stopTest();

        Integer invoiceCount = [
            SELECT COUNT()
            FROM VRT_Invoice__c
            WHERE VRT_LKP_Rental__c IN :new Set<Id>{ rental1.Id, rental2.Id }
        ];

        System.assertEquals(
            2,
            invoiceCount,
            'Debe crear una factura por cada alquiler completado en operación masiva.'
        );
    }
}