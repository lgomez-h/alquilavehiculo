# Arquitectura de AlquilaVehículo

## 1. Objetivo de la arquitectura

AlquilaVehículo comenzó como un proyecto centrado en la configuración y las funcionalidades básicas de Salesforce para gestionar vehículos y alquileres.

Durante el Track II el proyecto ha evolucionado incorporando lógica de precios, control de disponibilidad, aprobaciones financieras, una consola operativa, facturación asíncrona y búsqueda global de vehículos.

A medida que aumentaba la lógica del proyecto, también aumentaba la necesidad de separar responsabilidades. El objetivo ha sido evitar que toda la lógica quede concentrada en los componentes LWC, los triggers o los Flows.

Por este motivo, la aplicación utiliza principalmente dos caminos:

- Para las operaciones iniciadas desde la interfaz: `LWC → Controller → Service`.
- Para las operaciones provocadas por cambios en los alquileres: `Trigger → Handler → Service`.

Esta separación permite que cada parte tenga una responsabilidad más concreta y facilita la lectura, las pruebas y el mantenimiento del código.

## 2. Vista general

La aplicación tiene dos puntos principales de entrada a la lógica Apex.

### Operaciones iniciadas por el usuario

La Consola Operativa utiliza la siguiente estructura:

`rentalOperationsConsole → VRT_CLS_RentalConsoleController → VRT_CLS_RentalService`

El componente LWC se ocupa de la interacción con el usuario. El Controller expone a LWC los métodos que puede utilizar y delega la lógica de negocio en `VRT_CLS_RentalService`.

Actualmente la consola utiliza el Controller para:

- consultar los alquileres activos de una cuenta;
- obtener vehículos disponibles para unas fechas;
- simular el precio de un alquiler;
- crear un nuevo alquiler.

El Buscador Global de Flota es un caso más sencillo:

`vehicleSearch → VRT_CLS_VehicleSearchService`

En este caso no se añadió un Controller intermedio porque el componente únicamente necesita realizar una operación de búsqueda. Añadir otra clase que se limitara a reenviar la misma llamada no aportaría una separación útil.

### Operaciones provocadas por cambios en los datos

Los cambios sobre `VRT_Rental__c` pueden activar lógica que no depende directamente de la interfaz.

El flujo principal es:

`VRT_TRG_Rental → VRT_TRG_RentalHandler → Services`

El trigger identifica el contexto de ejecución, por ejemplo `before insert`, `before update` o `after update`, y delega el trabajo en el Handler.

El Handler, a su vez, utiliza servicios especializados para realizar la lógica correspondiente, entre ellos:

- `VRT_CLS_RentalService`
- `VRT_CLS_ApprovalService`
- `VRT_CLS_InvoiceQueueable`

De esta forma, el trigger no se convierte en una clase que contiene toda la lógica de negocio de los alquileres.

## 3. LWC, Controller y Service

### 3.1 Componentes LWC

La interfaz desarrollada para Track II utiliza dos componentes Lightning Web Components:

- `rentalOperationsConsole`
- `vehicleSearch`

Los componentes LWC se encargan principalmente de presentar información, recoger las acciones del usuario y llamar a Apex cuando necesitan ejecutar lógica en el servidor.

La intención es evitar que la lógica principal del negocio dependa del componente visual.

### 3.2 Consola Operativa

`rentalOperationsConsole` es el componente principal para trabajar con los alquileres desde la página de una cuenta.

El componente llama a cuatro métodos Apex:

- `getActiveRentals`
- `getAvailableVehicles`
- `simulateRentalPrice`
- `createRental`

Estas llamadas llegan a:

`VRT_CLS_RentalConsoleController`

El Controller actúa como punto de entrada entre LWC y Apex, pero no realiza directamente la lógica principal. Sus métodos delegan en:

`VRT_CLS_RentalService`

La estructura es, por tanto:

`rentalOperationsConsole → VRT_CLS_RentalConsoleController → VRT_CLS_RentalService`

Esta separación permite modificar o probar la lógica del alquiler sin depender directamente del componente LWC.

Por ejemplo, cuando el usuario quiere simular el precio, el componente no calcula el importe utilizando JavaScript. Solicita el cálculo a Apex para utilizar la misma lógica de negocio que utiliza Salesforce al crear el alquiler.

Esto evita tener dos cálculos diferentes, uno en JavaScript y otro en Apex, que podrían producir resultados distintos.

### 3.3 Buscador Global de Flota

El componente `vehicleSearch` permite realizar búsquedas sobre los vehículos.

Su estructura es más sencilla:

`vehicleSearch → VRT_CLS_VehicleSearchService.searchVehicles()`

El servicio utiliza SOSL para realizar la búsqueda y limita el número de resultados devueltos.

En este caso no se añadió un Controller adicional porque únicamente existe una operación de búsqueda y una clase intermedia no aportaría lógica adicional.

El servicio también aplica controles de seguridad antes de devolver los registros, comprobando el acceso al objeto y utilizando `Security.stripInaccessible()` para evitar devolver campos que el usuario no pueda consultar.

### 3.4 Responsabilidad del Service

Las clases Service concentran lógica que puede ser utilizada desde diferentes puntos de la aplicación.

Un ejemplo importante es `VRT_CLS_RentalService`.

Esta clase no pertenece exclusivamente a la Consola Operativa. También es utilizada desde `VRT_TRG_RentalHandler` para operaciones relacionadas con los alquileres.

Esto permite que una misma regla de negocio pueda utilizarse tanto cuando una operación empieza desde un LWC como cuando Salesforce ejecuta un trigger.

La idea puede resumirse así:

Interfaz:

`LWC → Controller → Service`

Automatización:

`Trigger → Handler → Service`

Ambos caminos pueden terminar utilizando la misma lógica de negocio.

## 4. Trigger, Handler y Services

### 4.1 Trigger de alquileres

El objeto `VRT_Rental__c` utiliza el trigger `VRT_TRG_Rental` para ejecutar lógica automáticamente cuando se crean o modifican alquileres.

El trigger no contiene directamente toda la lógica de negocio. Su función principal es identificar el contexto en el que se está ejecutando y delegar el trabajo en:

`VRT_TRG_RentalHandler`

La estructura general es:

`VRT_TRG_Rental → VRT_TRG_RentalHandler → Services`

Esto permite mantener el trigger pequeño y separar las diferentes responsabilidades.

### 4.2 Uso de before y after

La lógica se ejecuta en distintos momentos dependiendo de lo que necesitemos hacer.

En los contextos `before` se realizan principalmente operaciones que deben validarse o calcularse antes de guardar el alquiler.

Entre ellas se encuentran:

- validar la disponibilidad del vehículo;
- calcular el precio del alquiler;
- validar cambios de estado;
- actualizar información relacionada con el proceso de aprobación.

Cuando modificamos campos del propio alquiler en un contexto `before`, podemos trabajar directamente sobre los registros de `Trigger.new`. No es necesario realizar otro `update`, ya que Salesforce guardará esos valores como parte de la operación que ya está en curso.

Los contextos `after` se utilizan cuando necesitamos trabajar con información que ya ha sido guardada o iniciar procesos posteriores.

Un ejemplo importante es la facturación. Cuando un alquiler pasa a `Completado`, el Handler puede iniciar el proceso asíncrono de creación de la factura.

### 4.3 Handler

`VRT_TRG_RentalHandler` coordina las acciones que deben ejecutarse en cada contexto del trigger.

Entre otras operaciones, utiliza:

- `VRT_CLS_RentalService` para reglas relacionadas con alquileres, precios, disponibilidad y estados;
- `VRT_CLS_ApprovalService` para parte de la lógica del proceso de aprobación;
- `VRT_CLS_InvoiceQueueable` para iniciar la facturación asíncrona.

También existe `VRT_TRG_RentalHandlerHelper`, utilizado para separar operaciones auxiliares relacionadas con el ciclo de vida del alquiler y del vehículo.

El objetivo del Handler es coordinar estas operaciones, no concentrar en él toda la lógica que realizan.

### 4.4 Bulkificación

La lógica del trigger se ha diseñado teniendo en cuenta que Salesforce puede procesar varios registros en una misma transacción.

Por este motivo se trabaja con colecciones como:

- `List`
- `Set`
- `Map`

en lugar de asumir que `Trigger.new` contiene un único alquiler.

Por ejemplo, los identificadores necesarios para realizar consultas pueden recogerse primero en un `Set<Id>` y después utilizarse en una consulta conjunta.

La idea es evitar patrones como realizar una consulta SOQL o una operación DML por cada registro dentro de un bucle.

Esto es importante en Salesforce porque cada transacción está sujeta a límites de ejecución o governor limits.

### 4.5 Una misma lógica desde distintos puntos

Una de las ventajas de separar la lógica en Services es que las reglas importantes no tienen que pertenecer exclusivamente al trigger.

Por ejemplo, `VRT_CLS_RentalService` puede ser utilizado desde:

`rentalOperationsConsole → RentalConsoleController → RentalService`

y también desde:

`VRT_TRG_Rental → RentalHandler → RentalService`

De esta forma, la interfaz y las automatizaciones pueden compartir las mismas reglas de negocio en lugar de mantener implementaciones independientes.

## 5. Pricing Engine y disponibilidad

### 5.1 Pricing Engine

El cálculo automático del precio es una de las principales funcionalidades incorporadas durante el Track II.

La lógica de precios se ha separado de la interfaz y del trigger para evitar que las reglas de cálculo queden repartidas por distintas partes de la aplicación.

La estructura principal es:

`RentalConsoleController / RentalHandler → VRT_CLS_RentalService → VRT_CLS_PricingService`

`VRT_CLS_PricingService` se encarga de la lógica específica de precios, mientras que `VRT_CLS_RentalService` coordina su utilización dentro del proceso de alquiler.

El cálculo tiene en cuenta diferentes factores, entre ellos:

- tipo de vehículo;
- temporada;
- duración del alquiler;
- fidelidad del cliente;
- posible devolución con retraso.

### 5.2 Tarifas mediante Custom Metadata

Las tarifas no están escritas directamente en el código Apex.

Para configurarlas se utiliza:

`VRT_PricingRule__mdt`

El uso de Custom Metadata permite separar la configuración de precios de la lógica que realiza el cálculo.

De esta forma, una tarifa puede configurarse sin tener que modificar el código que implementa el Pricing Engine.

También permite detectar cuándo no existe una configuración válida. En ese caso, el alquiler no debe continuar con un precio inventado o incompleto, sino informar del problema.

### 5.3 Fidelidad del cliente

El Pricing Engine puede aplicar un descuento en función del historial de alquileres completados por el cliente.

Para obtener esta información se utiliza la lógica de métricas de alquileres y se tienen en cuenta los alquileres completados dentro del periodo establecido por la regla de negocio.

Durante el desarrollo se revisó esta lógica para que pudiera trabajar con varios alquileres dentro de una misma transacción, evitando realizar una consulta independiente por cada registro.

Esta decisión está relacionada con la bulkificación y con los governor limits de Salesforce.

### 5.4 Simulación y cálculo real

La Consola Operativa permite simular un precio antes de crear el alquiler.

La simulación utiliza la lógica Apex del Pricing Engine en lugar de reproducir las reglas de cálculo en JavaScript.

El objetivo es que la simulación y el cálculo que finalmente se realiza al guardar el alquiler utilicen las mismas reglas de negocio.

De esta forma se reduce el riesgo de mostrar al usuario un precio diferente del que posteriormente calcula Salesforce.

## 6. Disponibilidad de vehículos

La disponibilidad se valida antes de permitir que un alquiler utilice un vehículo para unas fechas determinadas.

Esta validación forma parte de la lógica de negocio del servidor y no depende únicamente de lo que muestre la interfaz.

Esto es importante porque un alquiler puede crearse o modificarse desde otros puntos de Salesforce además de la Consola Operativa.

La lógica principal se encuentra dentro de los servicios utilizados por el proceso de alquiler.

### 6.1 Detección de solapamientos

Para considerar que dos alquileres entran en conflicto se comprueba si sus periodos se solapan.

Conceptualmente, existe solapamiento cuando:

`inicioA < finB AND finA > inicioB`

Esta condición permite, por ejemplo, que un alquiler termine el mismo día en que comienza otro sin considerar automáticamente que ambos periodos se solapan.

La validación tiene en cuenta los estados del alquiler que realmente ocupan o reservan el vehículo.

### 6.2 Validación en servidor

Aunque la Consola Operativa muestra únicamente vehículos disponibles para las fechas seleccionadas, esta comprobación en la interfaz no sustituye a la validación del servidor.

La estructura es:

`LWC → consulta vehículos disponibles`

pero al guardar:

`Trigger → Handler → RentalService → validación de disponibilidad`

Esto proporciona dos niveles diferentes:

1. La interfaz intenta evitar que el usuario seleccione una opción que ya sabemos que no es válida.
2. El servidor vuelve a comprobar la regla antes de guardar los datos.

La segunda comprobación es la que garantiza la integridad de la información.

### 6.3 Procesamiento de varios registros

La disponibilidad también se diseñó teniendo en cuenta operaciones con varios alquileres en una misma transacción.

En lugar de consultar la base de datos individualmente para cada alquiler, se agrupan los identificadores y datos necesarios para realizar consultas conjuntas.

Con ello se intenta mantener la lógica compatible con el modelo de ejecución bulk de Salesforce.

## 7. Control financiero

Los alquileres de importe elevado necesitan un control adicional antes de continuar con su ciclo normal.

Para esta parte se combinan herramientas declarativas de Salesforce con lógica Apex:

`Rental → Approval Process / Flow → VRT_CLS_ApprovalService`

La decisión de utilizar un Approval Process permite aprovechar una funcionalidad estándar de Salesforce para gestionar aprobaciones, bloqueo del registro y trazabilidad, en lugar de construir todo el proceso únicamente mediante Apex.

La lógica desarrollada alrededor del proceso permite adaptar el comportamiento a las reglas del proyecto, incluyendo los diferentes niveles de aprobación según el importe.

También se controla qué ocurre cuando cambia el importe de un alquiler que ya había pasado por el proceso de aprobación. De esta forma, una aprobación anterior no debe considerarse automáticamente válida si las condiciones económicas del alquiler han cambiado.

Cuando una solicitud es rechazada, se conserva información sobre el rechazo para que el resultado del proceso pueda ser consultado posteriormente.

La intención es separar dos responsabilidades:

- Salesforce Approval Process gestiona el proceso de aprobación.
- Apex aplica las reglas de negocio necesarias alrededor de ese proceso.

## 8. Facturación asíncrona

Cuando un alquiler pasa al estado `Completado`, debe iniciarse el proceso de facturación.

La creación de la factura no se realiza directamente dentro de la operación principal del trigger. El Handler inicia un trabajo Queueable:

`RentalHandler → VRT_CLS_InvoiceQueueable`

El objetivo es separar la facturación de la transacción que está actualizando el alquiler.

### 8.1 Queueable y Service

`VRT_CLS_InvoiceQueueable` se encarga de iniciar la ejecución asíncrona, pero no contiene toda la lógica de creación de facturas.

El Queueable delega el trabajo en:

`VRT_CLS_InvoiceService.createInvoices()`

La separación es:

`Trigger → Handler → Queueable → InvoiceService`

De esta forma, el Queueable se ocupa del contexto asíncrono y el Service de la lógica de negocio de facturación.

### 8.2 Prevención de facturas duplicadas

Antes de crear una factura, `VRT_CLS_InvoiceService` comprueba si ya existe una asociada al alquiler.

Si ya existe, no crea una segunda factura y registra esta situación en `VRT_ProcessLog__c`.

Esta comprobación aporta una idempotencia básica al proceso: ejecutar nuevamente la operación para el mismo alquiler no debería producir otra factura.

En este proyecto la comprobación se realiza consultando las facturas existentes antes de insertar las nuevas.

### 8.3 Registro del proceso

El objeto `VRT_ProcessLog__c` se utiliza para dejar evidencia de la ejecución de la facturación.

El proceso puede registrar situaciones como:

- factura creada correctamente;
- intento de crear una factura que ya existía;
- error durante el procesamiento asíncrono.

Esto permite conocer posteriormente qué ocurrió durante un proceso que no necesariamente se ejecutó dentro de la misma transacción que utilizó el usuario.

### 8.4 Finalizer

El Queueable registra un `VRT_CLS_InvoiceFinalizer`.

Su función es comprobar el resultado final del trabajo asíncrono.

Si el Queueable termina correctamente, el Finalizer no necesita realizar ninguna acción adicional.

Si el trabajo falla, el Finalizer intenta registrar el error en `VRT_ProcessLog__c`.

La estructura es:

`InvoiceQueueable → InvoiceFinalizer`

El Finalizer proporciona un punto separado desde el que podemos reaccionar al resultado final del trabajo asíncrono.

### 8.5 Platform Event y notificación

Después de crear correctamente una factura, `VRT_CLS_InvoiceService` publica un Platform Event:

`VRT_InvoiceNotificationEvent__e`

El evento contiene la información necesaria para iniciar la notificación.

Un Flow suscrito al Platform Event recibe el evento:

`VRT_InvoiceNotificationEvent__e → Invoice_Notification_Flow`

El Flow comprueba si existe una dirección de correo electrónico y, cuando está disponible, ejecuta la acción de envío.

El flujo completo queda de esta forma:

`Alquiler completado`
`→ Trigger`
`→ Handler`
`→ Queueable`
`→ InvoiceService`
`→ creación de factura y log`
`→ Platform Event`
`→ Flow`
`→ email`

Esta solución permite que la creación de la factura y la notificación estén separadas. Apex publica que ha ocurrido un evento y el Flow se ocupa de la acción de comunicación.

## 9. Procesamiento Batch y Scheduled Apex

AlquilaVehículo también incluye un proceso para revisar periódicamente el estado de los vehículos.

Para esta funcionalidad se utilizan dos clases:

- `VRT_CLS_CheckVehicleRevision`
- `VRT_CLS_VehicleRevisionSchedule`

### 9.1 Batch Apex

`VRT_CLS_CheckVehicleRevision` implementa `Database.Batchable`.

Su objetivo es revisar los vehículos y determinar cuáles necesitan inspección en función de su antigüedad y tipo.

El uso de Batch Apex permite procesar los vehículos por grupos en lugar de intentar realizar todo el trabajo en una única ejecución.

El método `start()` obtiene los vehículos que deben ser revisados.

El método `execute()` recibe cada grupo de vehículos, aplica las reglas correspondientes y actualiza aquellos que necesitan inspección.

En este caso `finish()` no necesita realizar ninguna acción adicional, por lo que permanece vacío.

### 9.2 Scheduled Apex

`VRT_CLS_VehicleRevisionSchedule` implementa `Schedulable`.

Su responsabilidad es iniciar periódicamente el Batch:

`Scheduled Apex → VRT_CLS_CheckVehicleRevision → vehículos`

De esta forma se separan dos responsabilidades:

- el Schedule determina cuándo se ejecuta el proceso;
- el Batch determina cómo se procesan los vehículos.

La programación del Scheduled Job pertenece a la configuración de cada org y no queda creada automáticamente por el simple hecho de desplegar la clase Apex.

## 10. Seguridad

La seguridad se ha tenido en cuenta tanto en el código como en la configuración de permisos.

### 10.1 Acceso desde LWC

Las clases utilizadas directamente desde los componentes LWC aplican controles para evitar que la interfaz proporcione acceso a información que el usuario no debería consultar.

Por ejemplo, `VRT_CLS_VehicleSearchService` comprueba el acceso al objeto antes de realizar la búsqueda y utiliza `Security.stripInaccessible()` sobre los resultados.

También se utiliza `with sharing` en los puntos de entrada donde corresponde para respetar las reglas de acceso a registros del usuario.

### 10.2 Permission Set

Se creó el Permission Set:

`VRT_AlquilaVehiculo_User`

Su objetivo es proporcionar los permisos necesarios para utilizar las funcionalidades operativas sin recurrir a permisos generales como `View All` o `Modify All`.

El Permission Set incluye, entre otros:

- acceso a la aplicación;
- acceso a las clases Apex utilizadas desde LWC;
- permisos sobre los objetos necesarios;
- permisos de lectura o edición sobre los campos según su utilización.

Algunos campos calculados o controlados por la aplicación son únicamente de lectura para el usuario operativo.

La configuración de seguridad se documenta con más detalle en `security.md`.

## 11. Decisiones de diseño

Durante el desarrollo se han tomado varias decisiones con el objetivo de mantener el proyecto comprensible y evitar duplicar lógica.

Entre las principales se encuentran:

- separar la interfaz LWC de la lógica de negocio Apex;
- utilizar Controller cuando existe una interfaz con varias operaciones relacionadas;
- evitar un Controller adicional en el Buscador Global cuando no aportaba una responsabilidad nueva;
- mantener el trigger pequeño y delegar en Handler y Services;
- utilizar Custom Metadata para separar las tarifas de la lógica del Pricing Engine;
- validar reglas importantes, como la disponibilidad, en el servidor y no únicamente en JavaScript;
- reutilizar la lógica Apex de precios para la simulación y para el cálculo real;
- procesar colecciones de registros para respetar el modelo bulk de Salesforce;
- utilizar Queueable para separar la facturación de la transacción principal;
- comprobar la existencia previa de una factura para reducir el riesgo de duplicados;
- utilizar Finalizer para registrar fallos del proceso asíncrono;
- utilizar Platform Event y Flow para separar la facturación de la notificación;
- utilizar Batch y Scheduled Apex para procesos periódicos que pueden afectar a varios vehículos;
- definir un Permission Set específico para el usuario operativo.

El objetivo de estas decisiones no ha sido añadir capas o tecnologías innecesarias, sino utilizar cada herramienta cuando aporta una responsabilidad concreta.

## 12. Posibles mejoras futuras

El proyecto cubre los requisitos principales planteados para Track II, pero existen aspectos que podrían evolucionar en una aplicación real.

Algunas posibles mejoras son:

- reforzar el control de concurrencia para evitar casos extremos de creación simultánea de alquileres o facturas;
- ampliar el sistema de logs para facilitar la monitorización de procesos asíncronos;
- permitir una administración más completa de determinadas reglas de negocio mediante configuración;
- ampliar los perfiles de seguridad para diferenciar distintos tipos de usuarios operativos;
- mejorar la gestión y seguimiento de las notificaciones;
- preparar una estrategia de despliegue automatizada mediante CI/CD.

Estas mejoras no son necesarias para el funcionamiento actual del proyecto, pero representan posibles pasos posteriores si la aplicación siguiera evolucionando.