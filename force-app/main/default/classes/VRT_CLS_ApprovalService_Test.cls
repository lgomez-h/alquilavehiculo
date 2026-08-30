@IsTest
private class VRT_CLS_ApprovalService_Test {

    @IsTest
    static void testRejectionReasonIsCopiedFromApprovalComments() {

        // ========= ARRANGE =========

        Account account = new Account(
            Name = 'Cliente Approval Test'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '9090ZZZ',
            VRT_TXT_Brand__c = 'Ford',
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_SEL_Status__c = 'Listo',
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_NUM_Passengers__c = 4,
            VRT_FLG_Available__c = true,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
            VRT_FLG_NeedsInspection__c = false
        );
        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(10),
            VRT_DAT_FinalDate__c = Date.today().addDays(120)
        );

        insert rental;

        // Comprobamos que el Pricing Engine ha generado
        // un importe que requiere aprobación
        VRT_Rental__c submittedRental = [
            SELECT
                Id,
                VRT_DIV_TotalCost__c,
                VRT_SEL_ApprovalStatus__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assert(
            submittedRental.VRT_DIV_TotalCost__c > 3000,
            'El alquiler del test debe superar los 3000 euros.'
        );

        System.assertEquals(
            'Pending',
            submittedRental.VRT_SEL_ApprovalStatus__c,
            'El Flow debe enviar automáticamente el alquiler a aprobación.'
        );

        // ========= ACT =========

        Test.startTest();

        ProcessInstanceWorkitem workItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :rental.Id
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest rejectRequest =
            new Approval.ProcessWorkitemRequest();

        rejectRequest.setWorkitemId(workItem.Id);
        rejectRequest.setAction('Reject');
        rejectRequest.setComments('Importe no autorizado');

        Approval.ProcessResult rejectResult =
            Approval.process(rejectRequest);

        System.assert(
            rejectResult.isSuccess(),
            'El rechazo debería procesarse correctamente.'
        );

        Test.stopTest();

        // ========= ASSERT =========

        VRT_Rental__c rejectedRental = [
            SELECT
                VRT_SEL_Status__c,
                VRT_SEL_ApprovalStatus__c,
                VRT_TXT_Rejection_Reason__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assertEquals(
            'Cancelado',
            rejectedRental.VRT_SEL_Status__c,
            'El alquiler rechazado debe quedar Cancelado.'
        );

        System.assertEquals(
            'Rejected',
            rejectedRental.VRT_SEL_ApprovalStatus__c,
            'Approval Status debe quedar Rejected.'
        );

        System.assertEquals(
            'Importe no autorizado',
            rejectedRental.VRT_TXT_Rejection_Reason__c,
            'El motivo del rechazo debe copiarse desde los comentarios de la aprobación.'
        );
    }

    @IsTest
    static void testFinancialRejectionReasonIsCopied() {

        // ========= ARRANGE =========

        Account account = new Account(
            Name = 'Cliente Financial Approval Test'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '8080YYY',
            VRT_TXT_Brand__c = 'Ford',
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_SEL_Status__c = 'Listo',
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_NUM_Passengers__c = 4,
            VRT_FLG_Available__c = true,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
            VRT_FLG_NeedsInspection__c = false
        );
        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(10),
            VRT_DAT_FinalDate__c = Date.today().addDays(600)
        );

        insert rental;

        rental = [
            SELECT
                Id,
                VRT_DIV_TotalCost__c,
                VRT_SEL_ApprovalStatus__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assert(
            rental.VRT_DIV_TotalCost__c > 10000,
            'El alquiler del test debe superar los 10000 euros.'
        );

        System.assertEquals(
            'Pending',
            rental.VRT_SEL_ApprovalStatus__c
        );

        // ========= PRIMER PASO: GERENTE APRUEBA =========

        ProcessInstanceWorkitem managerWorkItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :rental.Id
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest managerApproval =
            new Approval.ProcessWorkitemRequest();

        managerApproval.setWorkitemId(managerWorkItem.Id);
        managerApproval.setAction('Approve');
        managerApproval.setComments('Aprobado por gerente');

        Approval.ProcessResult managerResult =
            Approval.process(managerApproval);

        System.assert(
            managerResult.isSuccess(),
            'La aprobación del gerente debe procesarse correctamente.'
        );

        // ========= SEGUNDO PASO: FINANCIERO RECHAZA =========

        ProcessInstanceWorkitem financialWorkItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :rental.Id
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest financialRejection =
            new Approval.ProcessWorkitemRequest();

        financialRejection.setWorkitemId(financialWorkItem.Id);
        financialRejection.setAction('Reject');
        financialRejection.setComments('Riesgo financiero');

        Test.startTest();

        Approval.ProcessResult financialResult =
            Approval.process(financialRejection);

        Test.stopTest();

        System.assert(
            financialResult.isSuccess(),
            'El rechazo financiero debe procesarse correctamente.'
        );

        // ========= ASSERT =========

        VRT_Rental__c rejectedRental = [
            SELECT
                VRT_SEL_Status__c,
                VRT_SEL_ApprovalStatus__c,
                VRT_TXT_Rejection_Reason__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assertEquals(
            'Cancelado',
            rejectedRental.VRT_SEL_Status__c
        );

        System.assertEquals(
            'Rejected',
            rejectedRental.VRT_SEL_ApprovalStatus__c
        );

        System.assertEquals(
            'Riesgo financiero',
            rejectedRental.VRT_TXT_Rejection_Reason__c,
            'Debe guardarse el comentario del rechazo del Responsable Financiero.'
        );
    }

    @IsTest
    static void testApprovalRestartsWhenAmountCrossesFinancialThreshold() {

        // ========= ARRANGE =========

        Account account = new Account(
            Name = 'Cliente Approval Amount Change'
        );
        insert account;

        VRT_Vehicle__c vehicle = new VRT_Vehicle__c(
            VRT_TXT_LicensePlate__c = '7070XXX',
            VRT_TXT_Brand__c = 'Ford',
            VRT_SEL_VehicleType__c = 'Coche',
            VRT_SEL_Status__c = 'Listo',
            VRT_SEL_EnergyType__c = 'Gasolina',
            VRT_NUM_Passengers__c = 4,
            VRT_FLG_Available__c = true,
            VRT_DAT_ManufacturedYear__c = Date.newInstance(2021, 1, 1),
            VRT_FLG_NeedsInspection__c = false
        );
        insert vehicle;

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = account.Id,
            VRT_LKP_Vehicle__c = vehicle.Id,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pagado',
            VRT_DAT_InitialDate__c = Date.today().addDays(10),
            VRT_DAT_FinalDate__c = Date.today().addDays(120)
        );

        insert rental;

        rental = [
            SELECT
                Id,
                VRT_DIV_TotalCost__c,
                VRT_SEL_ApprovalStatus__c,
                Approved_Amount__c,
                VRT_DAT_FinalDate__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        // Debemos empezar en el nivel Gerente
        System.assert(
            rental.VRT_DIV_TotalCost__c > 3000 &&
            rental.VRT_DIV_TotalCost__c <= 10000,
            'El coste inicial debe estar entre 3000 y 10000 euros.'
        );

        System.assertEquals(
            'Pending',
            rental.VRT_SEL_ApprovalStatus__c
        );

        // ========= GERENTE APRUEBA =========

        ProcessInstanceWorkitem managerWorkItem = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :rental.Id
            LIMIT 1
        ];

        Approval.ProcessWorkitemRequest managerApproval =
            new Approval.ProcessWorkitemRequest();

        managerApproval.setWorkitemId(managerWorkItem.Id);
        managerApproval.setAction('Approve');
        managerApproval.setComments('Aprobación inicial del gerente');

        Approval.ProcessResult managerResult =
            Approval.process(managerApproval);

        System.assert(
            managerResult.isSuccess(),
            'El gerente debe poder aprobar el alquiler inicial.'
        );

        // Comprobamos la primera aprobación
        rental = [
            SELECT
                VRT_DIV_TotalCost__c,
                VRT_SEL_ApprovalStatus__c,
                Approved_Amount__c,
                VRT_DAT_FinalDate__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assertEquals(
            'Approved',
            rental.VRT_SEL_ApprovalStatus__c
        );

        System.assertEquals(
            rental.VRT_DIV_TotalCost__c,
            rental.Approved_Amount__c,
            'Approved Amount debe guardar el importe inicialmente aprobado.'
        );

        Decimal originalApprovedAmount = rental.Approved_Amount__c;

        // ========= EL IMPORTE AUMENTA A > 10.000 =========

        rental.VRT_DAT_FinalDate__c = Date.today().addDays(600);

        Test.startTest();

        update rental;

        Test.stopTest();

        // ========= COMPROBAMOS NUEVA APROBACIÓN =========

        VRT_Rental__c increasedRental = [
            SELECT
                VRT_DIV_TotalCost__c,
                VRT_SEL_ApprovalStatus__c,
                Approved_Amount__c
            FROM VRT_Rental__c
            WHERE Id = :rental.Id
        ];

        System.assert(
            increasedRental.VRT_DIV_TotalCost__c > 10000,
            'El nuevo coste debe superar los 10000 euros.'
        );

        System.assertEquals(
            'Pending',
            increasedRental.VRT_SEL_ApprovalStatus__c,
            'El aumento del importe debe iniciar una nueva aprobación.'
        );

        System.assertEquals(
            originalApprovedAmount,
            increasedRental.Approved_Amount__c,
            'Approved Amount debe conservar el importe de la aprobación anterior hasta que termine la nueva.'
        );
    }
}