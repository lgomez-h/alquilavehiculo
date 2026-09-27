public with sharing class VRT_CLS_RentalService {

    public static void calculateRentalPrices(List<VRT_Rental__c> rentals)
    {
        Set<Id> vehicleIds = new Set<Id>();//para tipo de vehiculo
        Set<Id> accountsIds = new Set<id>();//para contar alquileres completados
        //Recojo VehicleIds y AccountIds en Sets.
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
        //cuento cuantos alquileres tiene cada account en los ultimos 12 meses
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

        Map<Id, VRT_Vehicle__c> vehiclesById =
            new Map<Id, VRT_Vehicle__c>([
                SELECT Id, VRT_SEL_VehicleType__c
                FROM VRT_Vehicle__c
                WHERE Id IN :vehicleIds
            ]);
        
        // Recorro los rentals para calcular el precio de cada uno
        for (VRT_Rental__c rental : rentals) {
            if (
                rental.VRT_LKP_Vehicle__c == null ||
                rental.VRT_LKP_Account__c == null ||
                rental.VRT_DAT_InitialDate__c == null ||
                rental.VRT_DAT_FinalDate__c == null
            ) {
                continue;
            }
            // recupero el tipo de vehiculo
            VRT_Vehicle__c vehicle =
                vehiclesById.get(rental.VRT_LKP_Vehicle__c);

            if (vehicle == null) {
                continue;
            }

            // recupero cuantos alquileres completados tiene la cuenta
            Integer completedRentals =
                completedRentalsByAccountId.get(rental.VRT_LKP_Account__c);

            if (completedRentals == null) {
                completedRentals = 0;
            }
            // llamo a pricingservice con todos los datos
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
    //Recojo en un Set los vehículos que necesito comprobar.
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
    //Miro los alquileresexistentes para esos vehiculos
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
            //si es el mismo Id no lo comparo
            if (oldMap != null && existingRental.Id == rental.Id) {
                continue;
            }
            //si son distintos vehiculos no lo comparo
            if (existingRental.VRT_LKP_Vehicle__c != rental.VRT_LKP_Vehicle__c) {
                continue;
            }
            //compruebo si las fechas se solapan
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
    // Comprueba si hay solapamiento entre los alquileres de la misma lista
    for (Integer i= 0; i < rentals.size(); i++) {
        VRT_Rental__c rentalA = rentals[i];

        if (
            rentalA.VRT_LKP_Vehicle__c == null ||
            rentalA.VRT_DAT_InitialDate__c == null ||
            rentalA.VRT_DAT_FinalDate__c == null ||
            (
                rentalA.VRT_SEL_Status__c != 'Reservado' &&
                rentalA.VRT_SEL_Status__c != 'En curso'
            )
        ) {
            continue;
        }
        for (Integer j = i + 1; j < rentals.size(); j++) {
            VRT_Rental__c rentalB = rentals[j];
            if (
            rentalB.VRT_LKP_Vehicle__c == null ||
            rentalB.VRT_DAT_InitialDate__c == null ||
            rentalB.VRT_DAT_FinalDate__c == null ||
            (
                rentalB.VRT_SEL_Status__c != 'Reservado' &&
                rentalB.VRT_SEL_Status__c != 'En curso'
            )
        ) {
            continue;
        }
        if (rentalA.VRT_LKP_Vehicle__c != rentalB.VRT_LKP_Vehicle__c) {
            continue;
        }
        Boolean datesOverlap =
            rentalA.VRT_DAT_InitialDate__c < rentalB.VRT_DAT_FinalDate__c &&
            rentalA.VRT_DAT_FinalDate__c > rentalB.VRT_DAT_InitialDate__c;
        if (datesOverlap) {
            rentalA.addError(
                'El vehículo no está disponible para las fechas seleccionadas.'
            );
            rentalB.addError(
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
    // Recupero los alquileres activos para la cuenta especificada
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
    // miro si el usuario tiene acceso a los campos de VRT_Rental__c y filtro los resultados en consecuencia
    SObjectAccessDecision accessDecision =
        Security.stripInaccessible(
            AccessType.READABLE,
            rentals
        );
    // Devuelvo los registros de alquileres filtrados
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
        // Obtengo los Ids de los vehículos no disponibles para el rango de fechas especificado
        Set<Id> unavailableVehicleIds =
        VRT_CLS_AvailabilityService.getUnavailableVehicleIds(
            startDate,
            endDate
        );
        // Recupero los vehículos disponibles que no están en la lista de vehículos no disponibles
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
        // miro si el usuario tiene acceso a los campos de VRT_Vehicle__c y filtro los resultados en consecuencia
        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.READABLE,
                vehicles
            );
        // Devuelvo los registros de vehículos filtrados
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
    // Recupero el vehículo para obtener su tipo
    VRT_Vehicle__c vehicle = [
        SELECT Id, VRT_SEL_VehicleType__c
        FROM VRT_Vehicle__c
        WHERE Id = :vehicleId
        LIMIT 1
    ];
    // Recupero la cantidad de alquileres completados del cliente en los últimos 12 meses
    Integer completedRentals =
        VRT_CLS_RentalMetricsService.countCompletedRentalsLast12Months(
            accountId
        );
    // Llamo a PricingService para calcular el precio final del alquiler
    return VRT_CLS_PricingService.calculateFinalPrice(
        vehicle.VRT_SEL_VehicleType__c,
        startDate,
        endDate,
        completedRentals,
        null
    );
    }
    // Crea un nuevo alquiler con los datos proporcionados
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
        // Creo un nuevo registro de alquiler con los datos proporcionados
        VRT_Rental__c rental = new VRT_Rental__c(
            VRT_LKP_Account__c = accountId,
            VRT_LKP_Vehicle__c = vehicleId,
            VRT_DAT_InitialDate__c = startDate,
            VRT_DAT_FinalDate__c = endDate,
            VRT_SEL_Status__c = 'Reservado',
            VRT_SEL_PaymentStatus__c = 'Pendiente'
        );
        // Verifico si el usuario tiene permisos para completar todos los campos necesarios del alquiler
        SObjectAccessDecision accessDecision =
            Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<VRT_Rental__c>{ rental }
            );
        // Si hay campos que el usuario no puede completar, lanzo una excepción de seguridad
        if (!accessDecision.getRemovedFields().isEmpty()) {
            throw new SecurityException(
                'No tienes permisos para completar todos los campos necesarios del alquiler.'
            );
        }
        // Inserto el nuevo registro de alquiler en la base de datos
        insert rental;
        return rental;
    }
    // Valida las transiciones de estado de los alquileres
    public static void validateStatusTransition(
        Map<Id, VRT_Rental__c> oldMap,
        Map<Id, VRT_Rental__c> newMap
    ) {
        // Recorro los alquileres para validar las transiciones de estado
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
    // Actualiza el estado de aprobación de los alquileres si el precio total cambia
  public static void updateApprovalStatusForAmountChange(
    List<VRT_Rental__c> rentals
) {
    // Recorro los alquileres
    for (VRT_Rental__c rental : rentals) {
        if (
            rental.VRT_SEL_ApprovalStatus__c == 'Approved' &&
            rental.VRT_DIV_TotalCost__c != null
        ) {
            // si cambia a <= 3000 pongo not required porque es una condicion en el flow
            if (rental.VRT_DIV_TotalCost__c <= 3000) {
                rental.VRT_SEL_ApprovalStatus__c = 'Not Required';
            }
            // si cambia a mayor de lo que tenia aprovado cambio para que vuelva a aprobarse
            else if (
                rental.Approved_Amount__c != null &&
                rental.VRT_DIV_TotalCost__c > rental.Approved_Amount__c
            ) {
                rental.VRT_SEL_ApprovalStatus__c = 'Not Required';
            }
        }
    }
}
}