public with sharing class VRT_CLS_RentalService {

    public static void calculateRentalPrices(List<VRT_Rental__c> rentals)
    {
        Set<Id> vehicleIds = new Set<Id>();
        Set<Id> accountsIds = new Set<id>();

        for (VRT_Rental__c rental : rentals) {
            if (rental.VRT_LKP_Vehicle__c != null) {
                vehicleIds.add(rental.VRT_LKP_Vehicle__c);
            }
            if (rental.VRT_LKP_Account__c != null) {
                accountsIds.add(rental.VRT_LKP_Account__c);
            }
        }
    
        if (vehicleIds.isEmpty()) {
            return;
        }


        Map<Id, VRT_Vehicle__c> vehiclesById =
            new Map<Id, VRT_Vehicle__c>([
                SELECT Id, VRT_SEL_VehicleType__c
                FROM VRT_Vehicle__c
                WHERE Id IN :vehicleIds
            ]);
        
        Map<Id, Integer> completedRentalsByAccountId = 
            new Map<Id, Integer>();

        if (!accountsIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT
                    VRT_LKP_Account__c accountId,
                    COUNT(Id) completedCount
                FROM VRT_Rental__c
                WHERE VRT_LKP_Account__c IN :accountsIds
                    AND VRT_SEL_Status__c = 'Completado'
                    AND VRT_DAT_FinalDate__c >= :Date.today().addMonths(-12)
                GROUP BY VRT_LKP_Account__c
            ]) {
                completedRentalsByAccountId.put(
                    (Id) ar.get('accountId'),
                    (Integer) ar.get('completedCount')
                );
            }
        }

        for (VRT_Rental__c rental : rentals) {
            if (
                rental.VRT_LKP_Vehicle__c == null ||
                rental.VRT_LKP_Account__c == null ||
                rental.VRT_DAT_InitialDate__c == null ||
                rental.VRT_DAT_FinalDate__c == null
            ) {
                continue;
            }

            VRT_Vehicle__c vehicle =
                vehiclesById.get(rental.VRT_LKP_Vehicle__c);

            if (vehicle == null) {
                continue;
            }

            Integer completedRentals =
                completedRentalsByAccountId.get(rental.VRT_LKP_Account__c);

            if (completedRentals == null) {
                completedRentals = 0;
            }

            rental.VRT_DIV_TotalCost__c =
                VRT_CLS_PricingService.calculateFinalPrice(
                    vehicle.VRT_SEL_VehicleType__c,
                    rental.VRT_DAT_InitialDate__c,
                    rental.VRT_DAT_FinalDate__c,
                    completedRentals,
                    rental.VRT_DAT_ActualReturnDate__c
                );
        }
    }

    public static void validateVehicleAvailability(
    List<VRT_Rental__c> rentals,
    Map<Id, VRT_Rental__c> oldMap
    ) {
    Set<Id> vehicleIds = new Set<Id>();

    for (VRT_Rental__c rental : rentals) {
        if (
            rental.VRT_LKP_Vehicle__c != null &&
            rental.VRT_DAT_InitialDate__c != null &&
            rental.VRT_DAT_FinalDate__c != null &&
            (
                rental.VRT_SEL_Status__c == 'Reservado' ||
                rental.VRT_SEL_Status__c == 'En curso'
            )
        ) {
            vehicleIds.add(rental.VRT_LKP_Vehicle__c);
        }
    }

    if (vehicleIds.isEmpty()) {
        return;
    }

    List<VRT_Rental__c> existingRentals = [
        SELECT Id,
               VRT_LKP_Vehicle__c,
               VRT_DAT_InitialDate__c,
               VRT_DAT_FinalDate__c,
               VRT_SEL_Status__c
        FROM VRT_Rental__c
        WHERE VRT_LKP_Vehicle__c IN :vehicleIds
        AND VRT_SEL_Status__c IN ('Reservado', 'En curso')
    ];

    for (VRT_Rental__c rental : rentals) {
        if (
            rental.VRT_LKP_Vehicle__c == null ||
            rental.VRT_DAT_InitialDate__c == null ||
            rental.VRT_DAT_FinalDate__c == null ||
            (
                rental.VRT_SEL_Status__c != 'Reservado' &&
                rental.VRT_SEL_Status__c != 'En curso'
            )
        ) {
            continue;
        }

        for (VRT_Rental__c existingRental : existingRentals) {
            if (oldMap != null && existingRental.Id == rental.Id) {
                continue;
            }

            if (existingRental.VRT_LKP_Vehicle__c != rental.VRT_LKP_Vehicle__c) {
                continue;
            }

            Boolean datesOverlap =
                rental.VRT_DAT_InitialDate__c < existingRental.VRT_DAT_FinalDate__c &&
                rental.VRT_DAT_FinalDate__c > existingRental.VRT_DAT_InitialDate__c;

            if (datesOverlap) {
                rental.addError(
                    'El vehículo no está disponible para las fechas seleccionadas.'
                );
            }
        }
    }
}

public static List<VRT_Rental__c> getActiveRentals(Id accountId) {

    if (!Schema.sObjectType.VRT_Rental__c.isAccessible()) {
        throw new SecurityException(
            'No tienes permisos para consultar alquileres.'
        );
    }

    if (!Schema.sObjectType.VRT_Vehicle__c.isAccessible()) {
        throw new SecurityException(
            'No tienes permisos para consultar vehículos.'
        );
    }

    if (accountId == null) {
        return new List<VRT_Rental__c>();
    }

    List<VRT_Rental__c> rentals = [
        SELECT
            Id,
            Name,
            VRT_LKP_Vehicle__r.VRT_TXT_Brand__c,
            VRT_LKP_Vehicle__r.VRT_TXT_LicensePlate__c,
            VRT_DAT_InitialDate__c,
            VRT_DAT_FinalDate__c,
            VRT_SEL_Status__c,
            VRT_DIV_TotalCost__c
        FROM VRT_Rental__c
        WHERE VRT_LKP_Account__c = :accountId
        AND VRT_SEL_Status__c IN ('Reservado', 'En curso')
        ORDER BY VRT_DAT_InitialDate__c ASC
    ];

    SObjectAccessDecision accessDecision =
        Security.stripInaccessible(
            AccessType.READABLE,
            rentals
        );
    
    return (List<VRT_Rental__c>) accessDecision.getRecords();
    }

    public static List<VRT_Vehicle__c> getAvailableVehicles(
    Date startDate,
    Date endDate
    ) {
        if (!Schema.sObjectType.VRT_Vehicle__c.isAccessible()) {
            throw new SecurityException(
                'No tienes permisos para consultar vehículos.'
            );
        }

        if (startDate == null || endDate == null) {
            return new List<VRT_Vehicle__c>();
        }
        
        Set<Id> unavailableVehicleIds =
        VRT_CLS_AvailabilityService.getUnavailableVehicleIds(
            startDate,
            endDate
        );

        List<VRT_Vehicle__c> vehicles = [
            SELECT
                Id,
                Name,
                VRT_TXT_LicensePlate__c,
                VRT_TXT_Brand__c,
                VRT_TXT_Model__c
            FROM VRT_Vehicle__c
            WHERE VRT_FLG_Available__c = true
            AND Id NOT IN :unavailableVehicleIds
            ORDER BY VRT_TXT_Brand__c, VRT_TXT_LicensePlate__c
        ];

        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.READABLE,
                vehicles
            );

        return (List<VRT_Vehicle__c>) accessDecision.getRecords();
    }

    public static Decimal simulateRentalPrice(
        Id accountId,
        Id vehicleId,
        Date startDate,
        Date endDate
    ) {

    if (!Schema.sObjectType.VRT_Vehicle__c.isAccessible()) {
        throw new SecurityException(
            'No tienes permisos para consultar vehículos.'
        );
    }

    if (!Schema.sObjectType.VRT_Vehicle__c
        .fields.VRT_SEL_VehicleType__c.isAccessible()) {
        throw new SecurityException(
            'No tienes permisos para consultar el tipo de vehículo.'
        );
    }
    
    if (
        accountId == null ||
        vehicleId == null ||
        startDate == null ||
        endDate == null
    ) {
        return null;
    }

    VRT_Vehicle__c vehicle = [
        SELECT Id, VRT_SEL_VehicleType__c
        FROM VRT_Vehicle__c
        WHERE Id = :vehicleId
        LIMIT 1
    ];

    Integer completedRentals =
        VRT_CLS_RentalMetricsService.countCompletedRentalsLast12Months(
            accountId
        );

    return VRT_CLS_PricingService.calculateFinalPrice(
        vehicle.VRT_SEL_VehicleType__c,
        startDate,
        endDate,
        completedRentals,
        null
    );
    }
    
    public static VRT_Rental__c createRental(
        Id accountId,
        Id vehicleId,
        Date startDate,
        Date endDate
    ) {

        if (!Schema.sObjectType.VRT_Rental__c.isCreateable()) {
            throw new SecurityException(
                'No tiene permisos para crear alquileres.'
            );
        }
        
        if (
            accountId == null ||
            vehicleId == null ||
            startDate == null ||
            endDate == null
        ) {
            throw new IllegalArgumentException(
                'Todos los datos del alquiler son obligatorios.'
            );
        }

        if (startDate >= endDate) {
            throw new IllegalArgumentException(
                'La fecha fin debe ser posterior a la fecha inicio.'
            );
        }

        if (startDate < Date.today()) {
            throw new IllegalArgumentException(
                'La fecha de inicio no puede ser anterior a hoy.'
            );
        }

        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = accountId,
            VRT_LKP_Vehicle__c = vehicleId,
            VRT_DAT_InitialDate__c = startDate,
            VRT_DAT_FinalDate__c = endDate,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pendiente'
        );
        
        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<VRT_Rental__c>{ rental }
            );

        if (!accessDecision.getRemovedFields().isEmpty()) {
            throw new SecurityException(
                'No tienes permisos para completar todos los campos necesarios del alquiler.'
            );
        }

        insert rental;
        return rental;
    }

    public static void validateStatusTransition(
        Map<Id, VRT_Rental__c> oldMap,
        Map<Id, VRT_Rental__c> newMap
    ) {
        for (Id rentalId : newMap.keySet()) {

            VRT_Rental__c oldRental = oldMap.get(rentalId);
            VRT_Rental__c newRental = newMap.get(rentalId);

            String oldStatus = oldRental.VRT_SEL_Status__c;
            String newStatus = newRental.VRT_SEL_Status__c;

            // Si el estado no cambia, no tenemos nada que validar.
            if (oldStatus == newStatus) {
                continue;
            }

            // Desde Reservado solo permitimos En curso o Cancelado.
            if (
                oldStatus == 'Reservado' &&
                newStatus != 'En curso' &&
                newStatus != 'Cancelado'
            ) {
                newRental.addError(
                    'Un alquiler reservado solo puede pasar a En curso o Cancelado.'
                );
            }

            // Desde En curso solo permitimos Completado o Cancelado.
            if (
                oldStatus == 'En curso' &&
                newStatus != 'Completado' &&
                newStatus != 'Cancelado'
            ) {
                newRental.addError(
                    'Un alquiler en curso solo puede pasar a Completado o Cancelado.'
                );
            }

            // Completado es un estado final.
            if (oldStatus == 'Completado') {
                newRental.addError(
                    'Un alquiler completado no puede cambiar de estado.'
                );
            }

            // Cancelado también es un estado final.
            if (oldStatus == 'Cancelado') {
                newRental.addError(
                    'Un alquiler cancelado no puede cambiar de estado.'
                );
            }
        }
    }
}