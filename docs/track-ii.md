# Implementación del Track II

## Introducción

Track II amplía la aplicación AlquilaVehículo desarrollada inicialmente en Track I.

El objetivo de esta segunda fase ha sido resolver nuevos problemas de negocio mediante funcionalidades de Salesforce como Apex, Lightning Web Components, automatización declarativa, procesamiento asíncrono, seguridad y testing.

Este documento relaciona los principales requisitos de Track II con la solución finalmente implementada en el proyecto.

## 1. Pricing & Revenue Management

### Problema

En la versión inicial de AlquilaVehículo el coste del alquiler no disponía de un motor de precios capaz de aplicar automáticamente las diferentes reglas de negocio.

Track II requiere que el precio se calcule teniendo en cuenta:

- tipo de vehículo;
- temporada;
- duración del alquiler;
- fidelidad del cliente;
- devolución con retraso.

También debe impedirse el cálculo cuando no existe una tarifa configurada y la solución debe funcionar correctamente cuando Salesforce procesa varios alquileres en una misma transacción.

### Solución implementada

La lógica se ha centralizado principalmente en:

- `VRT_CLS_PricingService`
- `VRT_CLS_RentalService`
- `VRT_CLS_RentalMetricsService`
- `VRT_PricingRule__mdt`

`VRT_CLS_PricingService` contiene la lógica específica del cálculo de precios.

`VRT_CLS_RentalService` integra este cálculo dentro del proceso general del alquiler y permite utilizarlo tanto desde el trigger como desde la Consola Operativa.

`VRT_CLS_RentalMetricsService` se utiliza para consultar información relacionada con el historial de alquileres del cliente.

### Tarifas configurables

Las tarifas base se almacenan mediante Custom Metadata en:

`VRT_PricingRule__mdt`

La intención es evitar que los importes estén escritos directamente en el código Apex.

Esto separa dos conceptos:

- la tarifa es configuración;
- la forma de calcular el precio es lógica de negocio.

Si no existe una tarifa válida para la combinación necesaria, el proceso no debe continuar utilizando un importe incompleto o inventado.

### Temporadas

El Pricing Engine determina la temporada correspondiente a la fecha del alquiler.

Las temporadas definidas por el requisito son:

- Alta: enero, abril, julio, agosto y diciembre;
- Media: febrero, mayo, junio y septiembre;
- Baja: marzo, octubre y noviembre.

A partir de la temporada y del tipo de vehículo se obtiene la tarifa correspondiente.

### Fidelidad

El cliente puede obtener un descuento del 5 % cuando cumple el requisito de haber completado al menos tres alquileres durante los últimos doce meses.

Durante el desarrollo esta parte se revisó para evitar realizar una consulta independiente por cada alquiler procesado.

Esto permite que la lógica sea compatible con operaciones bulk y reduce el riesgo de alcanzar los governor limits de Salesforce.

### Devolución con retraso

Cuando la devolución real supera la fecha final prevista, se aplica la penalización definida por el requisito:

25 % adicional por cada día de retraso.

Para ello se utiliza la fecha real de devolución y se diferencia de la fecha inicialmente prevista para el alquiler.

### Simulación del precio

La Consola Operativa permite consultar el precio antes de crear el alquiler.

La simulación no reproduce las reglas del Pricing Engine en JavaScript. La petición llega desde:

`rentalOperationsConsole → VRT_CLS_RentalConsoleController → VRT_CLS_RentalService`

y utiliza la lógica Apex de precios.

De esta forma, la simulación y el cálculo real utilizan las mismas reglas.

### Integración con el trigger

Al crear o modificar un alquiler, el cálculo puede ejecutarse desde:

`VRT_TRG_Rental → VRT_TRG_RentalHandler → VRT_CLS_RentalService`

El cálculo se realiza antes de guardar cuando corresponde, por lo que el valor puede establecerse sobre el propio registro sin necesitar un `update` adicional del alquiler.

### Pruebas

La funcionalidad dispone de tests específicos para comprobar las diferentes partes del cálculo.

Entre los escenarios comprobados durante el desarrollo se encuentran:

- obtención de la tarifa;
- cálculo de temporada;
- cálculo del precio base;
- descuento por fidelidad;
- penalización por retraso;
- alquileres que atraviesan diferentes temporadas;
- procesamiento de varios registros.

La lógica de precios forma parte además de las pruebas de integración realizadas sobre el proceso de creación de alquileres.

## 2. Fleet Availability

### Problema

Track II requiere impedir que un mismo vehículo tenga dos alquileres activos cuyas fechas se solapen.

La validación debe realizarse antes de guardar el alquiler y debe funcionar correctamente cuando Salesforce procesa varios registros en una misma transacción.

Los estados que se consideran ocupación del vehículo son:

- `Reservado`
- `En curso`

### Solución implementada

La validación de disponibilidad se centraliza en `VRT_CLS_RentalService` y se ejecuta desde el proceso del trigger:

`VRT_TRG_Rental → VRT_TRG_RentalHandler → VRT_CLS_RentalService.validateVehicleAvailability()`

La comprobación se realiza tanto al crear un alquiler como cuando una modificación puede afectar a su disponibilidad.

De esta forma, la regla no depende exclusivamente de la Consola Operativa y también protege los datos si el alquiler se crea o modifica desde otro punto de Salesforce.

### Detección de solapamientos

Dos periodos se consideran solapados cuando se cumple:

`inicioA < finB AND finA > inicioB`

Por ejemplo:

Alquiler A: 10 - 15 de septiembre  
Alquiler B: 12 - 18 de septiembre

Existe conflicto porque ambos alquileres utilizan el vehículo durante parte del mismo periodo.

Sin embargo:

Alquiler A: 10 - 15 de septiembre  
Alquiler B: 15 - 20 de septiembre

no se considera automáticamente un solapamiento.

Esto permite que un alquiler termine el mismo día en que comienza el siguiente, tal como establece el requisito.

### Validación antes del guardado

La comprobación se realiza en contexto `before`.

Esto permite detectar el conflicto antes de que el alquiler quede guardado.

Cuando se encuentra un conflicto, se utiliza un error sobre el registro para impedir la operación y devolver información al usuario.

Esta decisión protege la integridad de los datos: no se guarda primero un alquiler incorrecto para intentar corregirlo después.

### Disponibilidad en la Consola Operativa

La Consola Operativa también puede consultar los vehículos disponibles para las fechas seleccionadas:

`rentalOperationsConsole`
`→ VRT_CLS_RentalConsoleController.getAvailableVehicles()`
`→ VRT_CLS_RentalService`

Esto mejora la experiencia del usuario porque intenta mostrar únicamente opciones válidas.

Sin embargo, esta consulta no sustituye a la validación realizada por el trigger.

La aplicación utiliza por tanto dos niveles:

1. La interfaz ayuda al usuario a seleccionar un vehículo disponible.
2. El servidor comprueba nuevamente la disponibilidad antes de guardar.

La validación del servidor es la que garantiza finalmente la regla de negocio.

### Bulkificación

La validación está preparada para trabajar con colecciones de alquileres.

Los identificadores de los vehículos se agrupan antes de realizar las consultas necesarias y los alquileres existentes se recuperan de forma conjunta.

Esto evita realizar una consulta SOQL independiente por cada registro.

También se tienen en cuenta los posibles conflictos entre los propios alquileres que están siendo procesados dentro de una misma transacción.

### Estado operativo del vehículo

Durante el desarrollo también se revisó la relación entre el estado operativo del vehículo y su disponibilidad.

La disponibilidad no debe interpretarse únicamente como un valor aislado de la interfaz. El estado del vehículo y los alquileres existentes deben mantenerse de forma coherente para evitar ofrecer como disponible un vehículo que no puede utilizarse.

### Pruebas

Los tests de disponibilidad comprueban distintos escenarios, entre ellos:

- creación de un alquiler cuando no existe conflicto;
- intento de utilizar un vehículo con fechas solapadas;
- periodos consecutivos en los que un alquiler termina cuando comienza otro;
- estados que realmente bloquean la disponibilidad;
- actualización de alquileres existentes;
- procesamiento de varios registros en una misma transacción.

## 3. Financial Control

### Problema

Track II establece un proceso de aprobación para los alquileres de importe elevado.

Las reglas principales son:

- los alquileres superiores a 3.000 € necesitan aprobación del Gerente;
- los alquileres superiores a 10.000 € necesitan además la aprobación del Responsable Financiero;
- mientras el alquiler está pendiente de aprobación debe quedar bloqueado;
- una aprobación o rechazo debe quedar registrado;
- si el alquiler es rechazado, debe pasar a `Cancelado` y conservarse el motivo;
- si cambia el importe después de una aprobación, debe comprobarse nuevamente si la aprobación sigue siendo válida.

### Solución implementada

Para esta funcionalidad se combinan herramientas estándar de Salesforce con lógica Apex.

Los principales componentes son:

- `Rental_Approval_Process`
- Flow asociado al proceso financiero
- `VRT_CLS_ApprovalService`
- `VRT_SEL_ApprovalStatus__c`
- `Approved_Amount__c`
- `VRT_TXT_Rejection_Reason__c`

La idea principal fue utilizar el Approval Process de Salesforce para aquello que la plataforma ya sabe gestionar y utilizar Apex para las reglas adicionales del proyecto.

### Niveles de aprobación

El importe del alquiler determina el nivel de aprobación necesario.

Para importes superiores a 3.000 € interviene el Gerente.

Cuando el importe supera los 10.000 €, el proceso requiere también la intervención del Responsable Financiero.

De esta forma, el nivel de control aumenta con el riesgo económico del alquiler.

### Bloqueo durante la aprobación

Mientras el alquiler se encuentra dentro del proceso de aprobación, el registro puede permanecer bloqueado mediante el mecanismo estándar del Approval Process.

Esto evita tener que desarrollar en Apex un sistema propio de bloqueo de registros.

El uso de una funcionalidad estándar de Salesforce simplifica esta parte y mantiene el proceso visible y administrable desde la propia plataforma.

### Seguimiento del estado

`VRT_SEL_ApprovalStatus__c` permite mantener información sobre la situación del alquiler dentro del proceso financiero.

También se utiliza `Approved_Amount__c` para conservar el importe que fue aprobado.

Este último dato es importante porque permite comparar posteriormente el importe aprobado con el importe actual del alquiler.

### Cambio del importe

Una aprobación no debe considerarse válida indefinidamente si cambia el importe que justificó esa aprobación.

Por este motivo, durante la actualización del alquiler se ejecuta lógica relacionada con:

`VRT_CLS_RentalService.updateApprovalStatusForAmountChange()`

El sistema puede detectar que el importe actual ya no coincide con las condiciones bajo las que se produjo la aprobación y actualizar el estado correspondiente.

La finalidad es evitar situaciones como:

`Alquiler aprobado por 4.000 € → precio modificado a 12.000 € → continúa aprobado`

El cambio económico debe volver a ser tenido en cuenta por el proceso financiero.

### Rechazo

Cuando una solicitud es rechazada, el alquiler debe pasar al estado `Cancelado`.

Además, el motivo del rechazo se conserva en:

`VRT_TXT_Rejection_Reason__c`

Parte de esta lógica se gestiona mediante:

`VRT_CLS_ApprovalService`

De esta forma, el resultado no queda únicamente dentro del historial técnico del Approval Process, sino que el alquiler conserva información útil sobre el rechazo.

### Combinación de configuración y código

Para esta funcionalidad no se eligió desarrollar todo mediante Apex.

La solución combina:

`Approval Process + Flow + Apex`

El Approval Process gestiona el flujo estándar de aprobación y el bloqueo.

El Flow permite automatizar determinadas acciones relacionadas con el resultado del proceso.

Apex se utiliza para las reglas que necesitan integrarse con el resto de la lógica del alquiler.

Esta combinación permite utilizar las herramientas estándar de Salesforce cuando resuelven directamente el problema y reservar Apex para los comportamientos específicos de AlquilaVehículo.

### Pruebas

La lógica financiera dispone de tests para comprobar los comportamientos implementados en Apex.

También se ha comprobado la integración del proceso con el ciclo de vida del alquiler, incluyendo cambios de importe y las acciones relacionadas con aprobación y rechazo.

## 4. Operations UX

### Problema

Track II plantea la necesidad de mejorar el trabajo diario del equipo de operaciones.

El usuario debe poder trabajar con los alquileres de un cliente desde la página de Account sin tener que navegar continuamente entre diferentes registros y pantallas.

Entre los requisitos se encuentran:

- consultar los alquileres activos de la cuenta;
- crear un alquiler sin abandonar la página;
- simular el precio antes de guardar;
- comprobar la disponibilidad del vehículo;
- mostrar errores de forma comprensible;
- filtrar y ordenar la información;
- actualizar los datos sin realizar una recarga completa de la página;
- respetar los permisos del usuario.

### Solución implementada

Se desarrolló el Lightning Web Component:

`rentalOperationsConsole`

El componente se utiliza en el contexto de una cuenta y recibe su `recordId`.

La estructura utilizada es:

`rentalOperationsConsole`
`→ VRT_CLS_RentalConsoleController`
`→ VRT_CLS_RentalService`

El LWC se encarga principalmente de la interacción con el usuario, mientras que las operaciones que necesitan acceder a Salesforce se realizan mediante Apex.

### Alquileres activos

La consola puede consultar los alquileres activos asociados a la cuenta mediante:

`getActiveRentals(accountId)`

La llamada sigue el recorrido:

`LWC → RentalConsoleController → RentalService`

El `accountId` procede del registro de Account desde el que se está utilizando el componente.

Esto permite que la misma consola pueda utilizarse para diferentes clientes sin tener que configurar un identificador de cuenta de forma fija.

### Consulta de vehículos disponibles

Cuando el usuario introduce las fechas necesarias para el alquiler, la consola puede solicitar los vehículos disponibles mediante:

`getAvailableVehicles(startDate, endDate)`

La disponibilidad mostrada en la interfaz ayuda a evitar selecciones incorrectas antes de intentar guardar el alquiler.

Esta comprobación no sustituye a la validación del servidor. Al guardar, la disponibilidad vuelve a comprobarse dentro del proceso del trigger.

### Simulación del precio

Antes de crear el alquiler, el usuario puede solicitar una simulación.

La llamada utiliza:

`simulateRentalPrice()`

La simulación se realiza en Apex y reutiliza la lógica del Pricing Engine.

Esto evita mantener una segunda implementación de las reglas de precios dentro del JavaScript del componente.

El precio mostrado antes de guardar y el precio calculado durante la creación parten, por tanto, de la misma lógica de negocio.

### Creación del alquiler

La consola permite crear un nuevo alquiler mediante:

`createRental()`

El usuario no necesita abandonar la página de Account para realizar esta operación.

El Controller recibe los datos proporcionados por el componente y delega la creación en `VRT_CLS_RentalService`.

A partir de ese momento también se ejecutan las automatizaciones normales asociadas a `VRT_Rental__c`, por lo que crear un alquiler desde la consola no evita las validaciones del trigger.

### Actualización de la interfaz

Después de determinadas operaciones se utiliza `refreshApex` para solicitar datos actualizados a Salesforce.

El objetivo es actualizar la información necesaria sin realizar una recarga completa de la página.

De esta forma, el usuario puede continuar trabajando dentro de la Consola Operativa después de crear o modificar información.

### Filtrado y ordenación

La consola permite trabajar con la información mostrada mediante opciones de filtrado y ordenación.

Estas operaciones facilitan la consulta de los alquileres cuando una cuenta dispone de varios registros y evitan que el usuario tenga que abandonar el componente para localizar la información que necesita.

### Gestión de errores

Las operaciones realizadas desde el LWC pueden recibir errores procedentes de Apex o de las validaciones ejecutadas durante el guardado.

El componente transforma estos resultados en mensajes que pueden mostrarse al usuario.

Esto permite informar, por ejemplo, de problemas relacionados con:

- datos obligatorios;
- disponibilidad del vehículo;
- configuración necesaria para calcular el precio;
- errores producidos durante la creación del alquiler.

La intención es que una regla de negocio que impide una operación no aparezca únicamente como un fallo técnico sin contexto para el usuario.

### Seguridad

La Consola Operativa no debe utilizarse como un mecanismo para evitar la seguridad configurada en Salesforce.

El acceso a la aplicación, las clases Apex, los objetos y los campos necesarios se gestiona mediante el Permission Set:

`VRT_AlquilaVehiculo_User`

Además, el Controller utiliza `with sharing` para respetar el acceso a registros del usuario.

La seguridad completa del proyecto se documenta de forma específica en `security.md`.

### Pruebas

`VRT_CLS_RentalConsoleController` dispone de tests para comprobar las operaciones expuestas a LWC.

Entre los escenarios comprobados se encuentra la creación de un alquiler desde el Controller y la verificación posterior de que el registro se ha creado con los valores esperados y con un precio calculado.

## 5. Post-Rental Processing

### Problema

Track II requiere automatizar las acciones posteriores a la finalización de un alquiler.

Cuando un alquiler cambia a `Completado`, el sistema debe:

- generar una factura;
- evitar crear facturas duplicadas;
- ejecutar el proceso sin bloquear innecesariamente la operación principal;
- dejar constancia del resultado;
- iniciar una notificación al cliente;
- registrar los posibles errores del procesamiento.

### Inicio del proceso

El proceso comienza cuando se detecta que un alquiler ha pasado al estado `Completado`.

El cambio se detecta dentro del ciclo del trigger:

`VRT_TRG_Rental → VRT_TRG_RentalHandler`

El Handler compara el estado anterior y el nuevo para determinar si realmente se ha producido la transición a `Completado`.

Cuando corresponde iniciar la facturación, los identificadores de los alquileres se agrupan y se inicia:

`VRT_CLS_InvoiceQueueable`

mediante `System.enqueueJob()`.

### Procesamiento asíncrono

La factura no se crea directamente dentro de la transacción que está actualizando el alquiler.

El recorrido es:

`RentalHandler`
`→ VRT_CLS_InvoiceQueueable`
`→ VRT_CLS_InvoiceService.createInvoices()`

El Queueable proporciona el contexto asíncrono y el Service contiene la lógica de negocio necesaria para crear las facturas.

Esta separación permite que la actualización principal del alquiler no tenga que realizar todo el procesamiento posterior dentro de la misma ejecución.

### Creación de la factura

`VRT_CLS_InvoiceService` crea registros de:

`VRT_Invoice__c`

utilizando la información del alquiler.

Entre los datos utilizados se encuentran:

- alquiler;
- cuenta;
- importe total;
- fecha de emisión;
- estado de la factura.

La factura queda relacionada con el alquiler que provocó su creación.

### Prevención de duplicados

Antes de insertar nuevas facturas, el Service consulta cuáles de los alquileres recibidos ya tienen una factura asociada.

Los identificadores encontrados se almacenan para poder excluirlos de la creación.

De esta forma, si el proceso vuelve a recibir un alquiler que ya fue facturado, no se genera otra factura para ese mismo alquiler.

La situación también puede quedar registrada en el log del proceso.

### Registro de ejecución

Para disponer de información sobre el resultado del procesamiento se utiliza:

`VRT_ProcessLog__c`

El log permite dejar constancia de situaciones como:

- factura creada correctamente;
- factura que no se crea porque ya existía;
- error producido durante el proceso.

Esto es especialmente útil en procesos asíncronos, ya que el resultado puede producirse después de que haya terminado la operación que realizó el usuario.

### Tratamiento de errores

`VRT_CLS_InvoiceQueueable` registra:

`VRT_CLS_InvoiceFinalizer`

El Finalizer se ejecuta al finalizar el Queueable y puede comprobar el resultado del trabajo.

Si el Queueable termina con error, el Finalizer intenta registrar información sobre el fallo en `VRT_ProcessLog__c`.

Esto proporciona una segunda vía para dejar evidencia de un problema producido durante el procesamiento asíncrono.

### Notificación mediante Platform Event

Cuando una factura se crea correctamente, `VRT_CLS_InvoiceService` prepara y publica:

`VRT_InvoiceNotificationEvent__e`

mediante `EventBus.publish()`.

El Platform Event separa la creación de la factura de la acción posterior de notificación.

El recorrido es:

`InvoiceService`
`→ VRT_InvoiceNotificationEvent__e`
`→ Invoice_Notification_Flow`

### Flow de notificación

`Invoice_Notification_Flow` recibe el Platform Event.

El Flow comprueba la información necesaria para realizar la notificación y, cuando dispone de una dirección válida, ejecuta la acción correspondiente de correo electrónico.

De esta forma, Apex no necesita contener directamente toda la lógica relacionada con la notificación.

### Flujo completo

El proceso puede resumirse así:

`Alquiler cambia a Completado`
`→ Trigger`
`→ Handler`
`→ Queueable`
`→ InvoiceService`
`→ VRT_Invoice__c`
`→ VRT_ProcessLog__c`
`→ Platform Event`
`→ Flow`
`→ notificación`

### Procesamiento de varios alquileres

El proceso trabaja con colecciones de identificadores de alquiler.

El Handler agrupa los alquileres que necesitan facturación y el Service procesa el conjunto recibido.

También se consultan conjuntamente las facturas existentes antes de decidir cuáles deben crearse.

Esto evita diseñar la facturación suponiendo que solamente se completará un alquiler en cada transacción.

### Pruebas

La facturación dispone de tests para comprobar, entre otros escenarios:

- creación de una factura para un alquiler completado;
- procesamiento de varios alquileres;
- prevención de facturas duplicadas;
- ejecución del procesamiento asíncrono;
- comportamiento del sistema cuando se producen errores.

Los tests utilizan `Test.startTest()` y `Test.stopTest()` cuando es necesario ejecutar y comprobar el trabajo asíncrono.

## 6. Search & Discoverability

### Problema

Track II requiere facilitar la localización de vehículos de la flota sin depender únicamente de la navegación por listas o registros individuales.

Para resolver este requisito se desarrolló un Buscador Global de Flota que permite introducir un término de búsqueda y obtener los vehículos relacionados.

### Solución implementada

La funcionalidad está formada principalmente por:

- `vehicleSearch`
- `VRT_CLS_VehicleSearchService`

El recorrido es:

`vehicleSearch → VRT_CLS_VehicleSearchService.searchVehicles()`

El LWC se ocupa de recoger el texto introducido por el usuario y presentar los resultados.

La búsqueda se realiza en Apex.

### Uso de SOSL

Para esta funcionalidad se utiliza SOSL.

SOSL resulta adecuado cuando queremos buscar un término de texto y localizar coincidencias en diferentes campos indexados sin construir una consulta independiente para cada uno de ellos.

La responsabilidad de construir y ejecutar la búsqueda queda dentro de `VRT_CLS_VehicleSearchService`.

De esta forma, el componente LWC no necesita conocer cómo se realiza internamente la búsqueda en Salesforce.

### Separación del componente y el Service

La estructura utilizada es más sencilla que la de la Consola Operativa:

`vehicleSearch → VehicleSearchService`

No se añadió un Controller adicional porque el componente solamente necesita una operación principal de búsqueda.

En este caso, una clase intermedia que se limitara a llamar al Service no aportaría una responsabilidad nueva.

### Limitación de resultados

La búsqueda limita el número de registros devueltos.

Esto evita devolver una cantidad innecesaria de información al componente y mantiene la funcionalidad orientada a localizar vehículos, no a realizar una extracción completa de la flota.

### Seguridad

Antes de devolver información al LWC, el Service aplica controles de seguridad.

Entre ellos se encuentran:

- comprobación del acceso al objeto;
- aplicación de `Security.stripInaccessible()` sobre los resultados.

Esto permite eliminar de la respuesta aquellos campos a los que el usuario no tenga acceso.

El Buscador Global no debe convertirse en una forma alternativa de consultar información que el usuario no podría consultar normalmente.

### Pruebas

`VRT_CLS_VehicleSearchService` dispone de tests para comprobar el comportamiento de la búsqueda y los principales escenarios contemplados por el servicio.

## 7. Technical Quality & DevOps

### Objetivo

Además de implementar las funcionalidades de negocio, Track II requiere prestar atención a la calidad técnica, las pruebas y el proceso de desarrollo y despliegue.

Durante el proyecto se han trabajado especialmente:

- separación de responsabilidades;
- bulkificación;
- tests Apex;
- seguridad;
- Salesforce DX;
- Salesforce CLI;
- control de versiones con Git;
- validación del despliegue.

### Organización del código

La lógica se ha dividido en diferentes tipos de clases según su responsabilidad.

La estructura principal utilizada es:

`LWC → Controller → Service`

para las operaciones iniciadas desde la interfaz, y:

`Trigger → Handler → Service`

para las automatizaciones relacionadas con cambios en los alquileres.

Los procesos que necesitan ejecutarse de forma asíncrona o periódica utilizan además Queueable, Finalizer, Batch y Scheduled Apex.

El objetivo de esta separación es evitar clases demasiado grandes y facilitar la lectura, las pruebas y el mantenimiento del código.

### Bulkificación

Los triggers y servicios que pueden recibir varios registros se han diseñado para trabajar con colecciones.

Se utilizan principalmente:

- `List`
- `Set`
- `Map`

Los identificadores necesarios se agrupan antes de realizar consultas y se intenta evitar SOQL o DML dentro de bucles.

Durante el desarrollo se revisaron específicamente algunas funcionalidades, como el cálculo del descuento por fidelidad y la disponibilidad de vehículos, para que pudieran trabajar correctamente con varios registros dentro de una misma transacción.

### Tests Apex

El proyecto incluye clases de test para las principales funcionalidades desarrolladas.

Las pruebas comprueban tanto unidades concretas de lógica como procesos que integran varias partes de la aplicación.

Entre las funcionalidades cubiertas se encuentran:

- Pricing Engine;
- fidelidad;
- penalización por retraso;
- disponibilidad;
- ciclo de vida del alquiler;
- aprobación financiera;
- Consola Operativa;
- facturación asíncrona;
- prevención de facturas duplicadas;
- Buscador Global de Flota;
- procesos relacionados con vehículos.

Los tests utilizan datos creados específicamente para cada escenario y no dependen de los datos existentes en la org.

Cuando es necesario comprobar procesamiento asíncrono se utilizan `Test.startTest()` y `Test.stopTest()`.

### Validación completa del proyecto

Antes de preparar la entrega se realizó una validación completa del despliegue mediante Salesforce CLI utilizando:

`sf project deploy start --source-dir force-app --dry-run --test-level RunLocalTests --wait 30`

El resultado final fue:

- Passing: 73
- Failing: 0
- Total: 73

El uso de `--dry-run` permite comprobar el despliegue y ejecutar los tests sin realizar el despliegue definitivo de los cambios.

### Salesforce DX y CLI

El proyecto utiliza la estructura de Salesforce DX.

El código y la metadata se encuentran principalmente dentro de:

`force-app/main/default`

Durante el desarrollo se ha utilizado Salesforce CLI para tareas como:

- recuperar metadata desde la org;
- desplegar cambios;
- ejecutar tests;
- validar despliegues;
- consultar metadata;
- trabajar con Custom Metadata.

Esto permite que el proyecto no dependa únicamente de la configuración realizada manualmente desde Setup.

### Control de versiones

El proyecto utiliza Git y GitHub para mantener el historial de cambios.

El desarrollo se ha realizado mediante ramas de funcionalidad, entre ellas:

- `feature/pricing-engine`
- `feature/operations-console`
- `feature/financial-control`

Los cambios se han ido guardando mediante commits que representan pasos concretos del desarrollo.

Antes de preparar la integración final, la rama de trabajo se sincronizó con `master` para comprobar que contiene los cambios de la rama principal y evitar integrar sobre una base desactualizada.

### Seguridad y despliegue

También se ha creado el Permission Set:

`VRT_AlquilaVehiculo_User`

Su configuración forma parte de la metadata del proyecto, por lo que puede desplegarse junto con el resto de la aplicación.

Esto permite definir de forma explícita los permisos que necesita un usuario operativo en lugar de asumir que utilizará un perfil de administrador.

Los detalles sobre estos permisos se documentan en `security.md`.

### Portabilidad

El objetivo es que el repositorio contenga no solo el código Apex y los componentes LWC, sino también la metadata necesaria para reproducir la aplicación en otra org compatible.

Sin embargo, existen configuraciones que pueden requerir una acción posterior al despliegue.

Un ejemplo es la programación de un Scheduled Apex Job: desplegar la clase `Schedulable` no significa que Salesforce cree automáticamente una ejecución programada.

Estas acciones posteriores se recogerán en `deployment.md`.

## Conclusión

La evolución realizada durante Track II convierte AlquilaVehículo en un proyecto que combina configuración declarativa y desarrollo programático sobre Salesforce.

La solución utiliza Apex, LWC, SOQL/SOSL, Custom Metadata, Approval Process, Flow, Platform Events y diferentes formas de procesamiento asíncrono.

Durante el desarrollo no solo se ha buscado cumplir cada requisito de forma aislada, sino también mantener una estructura que permita comprender dónde se encuentra cada responsabilidad y cómo se relacionan las diferentes partes de la aplicación.