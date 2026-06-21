public with sharing class VRT_CLS_RentalService {

    public static Integer countCompletedRentalsLast12Months(
        Id accountId
    ) {
            Integer completedRentals = [
            SELECT COUNT()
            FROM VRT_Rental__c
            WHERE VRT_LKP_Account__c = :accountId
            AND VRT_SEL_Status__c = 'Completado'
            AND VRT_DAT_FinalDate__c >= :Date.today().addMonths(-12)
            ];

    return completedRentals; 


    }
}