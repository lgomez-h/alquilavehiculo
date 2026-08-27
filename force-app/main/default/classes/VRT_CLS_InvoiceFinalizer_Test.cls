@IsTest
private class VRT_CLS_InvoiceFinalizer_Test {

        private class FailingQueueable implements Queueable {

        private Set<Id> rentalIds;

        FailingQueueable(Set<Id> rentalIds) {
            this.rentalIds = rentalIds;
        }

        public void execute(QueueableContext context) {

            System.attachFinalizer(
                new VRT_CLS_InvoiceFinalizer(rentalIds)
            );

            Integer zero = 0;
            Integer result = 10 / zero;
        }
    }

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

private static VRT_Rental__c createRental(
    Id accountId,
    Id vehicleId
) {
    VRT_Rental__c rental = new VRT_Rental__c(
        VRT_LKP_Account__c = accountId,
        VRT_LKP_Vehicle__c = vehicleId,
        VRT_SEL_Status__c = 'En curso',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today(),
        VRT_DAT_FinalDate__c = Date.today().addDays(1)
    );

    insert rental;
    return rental;
}

@IsTest
static void testCreatesErrorLogWhenQueueableFails() {

    Account account = new Account(
        Name = 'Cliente Finalizer Test'
    );
    insert account;

    VRT_Vehicle__c vehicle =
        createVehicle('5555EEE');

    VRT_Rental__c rental =
        createRental(account.Id, vehicle.Id);

    Test.startTest();

    System.enqueueJob(
        new FailingQueueable(
            new Set<Id>{ rental.Id }
        )
    );

    try {
        Test.stopTest();
    } catch (MathException e) {
        // La excepción es intencionada:
        // queremos que el Queueable falle.
    }

    List<VRT_ProcessLog__c> errorLogs = [
        SELECT
            Id,
            VRT_LKP_Rental__c,
            Status__c,
            VRT_Message__c
        FROM VRT_ProcessLog__c
        WHERE VRT_LKP_Rental__c = :rental.Id
        AND Status__c = 'Error'
    ];

    System.assertEquals(
        1,
        errorLogs.size(),
        'Debe crearse un log de error cuando falla el Queueable.'
    );

    System.assertEquals(
        rental.Id,
        errorLogs[0].VRT_LKP_Rental__c,
        'El log debe estar asociado al alquiler que se estaba procesando.'
    );

    System.assertEquals(
        'Error',
        errorLogs[0].Status__c,
        'El log debe quedar registrado con estado Error.'
    );
}
    
}