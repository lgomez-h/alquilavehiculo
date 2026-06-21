@IsTest
private class VRT_CLS_RentalService_Test {
    @testSetup
    static void setupData() {
    Account account = new Account(
        Name = 'Cliente Test'
    );
    insert account;

    Account account2 = new Account(
        Name = 'Cliente Test 2'
    );
    insert account2;

    List<VRT_Rental__c> rentals = new List<VRT_Rental__c>();

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-2),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-2).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-4),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-4).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-6),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-6).addDays(3)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Cancelado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-1),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-1).addDays(2)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-18),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-18).addDays(2)
    ));

    rentals.add(new VRT_Rental__c(
        VRT_LKP_Account__c = account2.Id,
        VRT_SEL_Status__c = 'Completado',
        VRT_SEL_PaymentStatus__c = 'Pagado',
        VRT_DAT_InitialDate__c = Date.today().addMonths(-3),
        VRT_DAT_FinalDate__c = Date.today().addMonths(-3).addDays(3)
    ));

    insert rentals;
    }

    @IsTest
static void testCountCompletedRentalsLast12Months() {

    Account account = [
        SELECT Id
        FROM Account
        WHERE Name = 'Cliente Test'
        LIMIT 1
    ];

    Integer completedRentals =
        VRT_CLS_RentalService.countCompletedRentalsLast12Months(
            account.Id
        );

    System.assertEquals(
        3,
        completedRentals,
        'Debe contar únicamente los alquileres completados de los últimos 12 meses.'
    );
}


}