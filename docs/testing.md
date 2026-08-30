# Estrategia de pruebas

## 1. Objetivo

Los tests de AlquilaVehículo no se utilizan únicamente para alcanzar el porcentaje mínimo de cobertura exigido por Salesforce.

El objetivo principal es comprobar que las reglas de negocio funcionan en distintos escenarios y que los cambios realizados durante Track II no rompen funcionalidades existentes.

También se han incluido pruebas con varios registros para comprobar que la lógica puede trabajar siguiendo el modelo bulk de Salesforce.

## 2. Datos de prueba

Las clases de test crean los datos necesarios para cada escenario.

Entre ellos se encuentran:

- Accounts;
- vehículos;
- alquileres;
- tarifas necesarias para los cálculos;
- datos relacionados con los diferentes procesos.

Los tests no deben depender de los registros existentes en la org.

Esto permite que puedan ejecutarse en diferentes entornos sin necesitar que existan previamente los mismos clientes, vehículos o alquileres.

## 3. Estructura Arrange, Act, Assert

En diferentes tests se utiliza una estructura basada en:

`Arrange → Act → Assert`

### Arrange

Se preparan los datos y las condiciones necesarias para ejecutar el escenario.

### Act

Se ejecuta la operación que queremos probar.

### Assert

Se comprueba que el resultado obtenido coincide con el comportamiento esperado.

Por ejemplo, en el test de creación desde la Consola Operativa:

- Arrange: se crean una Account, un vehículo y las fechas;
- Act: se ejecuta `VRT_CLS_RentalConsoleController.createRental()`;
- Assert: se comprueba que el alquiler existe y contiene los valores esperados.

Esta estructura ayuda a entender qué está preparando el test, qué está ejecutando y qué está comprobando.

## 4. Pricing Engine

Los tests del Pricing Engine comprueban diferentes partes del cálculo.

Entre los escenarios trabajados se encuentran:

- obtención de tarifas;
- determinación de la temporada;
- cálculo del precio base;
- descuento por fidelidad;
- penalización por devolución con retraso;
- alquileres que afectan a diferentes temporadas;
- procesamiento de varios registros.

Estas pruebas permiten comprobar las reglas individualmente antes de utilizarlas dentro del proceso completo del alquiler.

## 5. Disponibilidad

La disponibilidad se prueba con diferentes combinaciones de fechas y estados.

Entre los casos importantes se encuentran:

- vehículo disponible;
- fechas que se solapan;
- alquileres consecutivos sin solapamiento;
- actualización de un alquiler existente;
- procesamiento de varios alquileres.

Las pruebas bulk son especialmente importantes porque el trigger no puede asumir que `Trigger.new` contiene siempre un único registro.

## 6. Control financiero

Los tests relacionados con el control financiero comprueban la lógica Apex que acompaña al proceso de aprobación.

Entre los comportamientos revisados se encuentran los cambios en el importe del alquiler y la actualización de la información utilizada por el proceso financiero.

El Approval Process también contiene comportamiento declarativo de Salesforce, por lo que no toda la funcionalidad financiera se reduce a una única clase Apex.

## 7. Consola Operativa

`VRT_CLS_RentalConsoleController` dispone de tests sobre los métodos utilizados por el LWC.

Un ejemplo es la creación de un alquiler mediante:

`createRental()`

Después de ejecutar el método se consulta el registro guardado y se comprueba, entre otros valores:

- que dispone de Id;
- que el estado esperado se ha establecido;
- que el estado de pago es correcto;
- que el Pricing Engine ha generado un coste total.

Esto permite comprobar la integración entre el Controller y la lógica de negocio utilizada durante la creación.

## 8. Procesamiento asíncrono

Los procesos Queueable necesitan una consideración especial durante los tests.

Cuando es necesario ejecutar y comprobar el trabajo asíncrono se utiliza:

`Test.startTest()`

y:

`Test.stopTest()`

`Test.startTest()` delimita la parte principal que queremos probar y proporciona un nuevo conjunto de governor limits para esa sección.

`Test.stopTest()` provoca la ejecución de los trabajos asíncronos encolados durante el test antes de continuar con las comprobaciones posteriores.

Esto permite comprobar el resultado de procesos como la generación automática de facturas.

## 9. Facturación

Los tests de facturación comprueban escenarios como:

- creación de factura para un alquiler completado;
- procesamiento de varios alquileres;
- prevención de facturas duplicadas;
- comportamiento del Queueable;
- registro de resultados y errores cuando corresponde.

Una prueba importante consiste en volver a procesar un alquiler que ya tiene factura y comprobar que no se crea otra.

## 10. Buscador Global de Flota

`VRT_CLS_VehicleSearchService` dispone de tests para comprobar el comportamiento del servicio utilizado por `vehicleSearch`.

Estos tests permiten validar la lógica Apex independientemente del componente visual.

## 11. Pruebas bulk

Una parte importante de la revisión realizada durante Track II ha sido comprobar que la aplicación no esté diseñada suponiendo que Salesforce procesa los registros de uno en uno.

Para ello se utilizan colecciones como:

- `List`
- `Set`
- `Map`

y se incluyen tests que procesan varios registros en una misma operación cuando la funcionalidad lo requiere.

El objetivo es detectar problemas como:

`SOQL dentro de un bucle`

o:

`DML dentro de un bucle`

que podrían provocar errores al alcanzar los governor limits.

## 12. Validación final

Antes de preparar la entrega se realizó una validación completa del contenido de `force-app` mediante:

`sf project deploy start --source-dir force-app --dry-run --test-level RunLocalTests --wait 30`

El resultado obtenido fue:

- Passing: 73
- Failing: 0
- Total: 73

El comando utiliza `--dry-run`, por lo que Salesforce valida el despliegue y ejecuta los tests sin aplicar nuevamente los cambios en la org.

Esta comprobación permite verificar conjuntamente que la metadata puede desplegarse y que los tests locales siguen pasando.

## 13. Cobertura y calidad

La cobertura de código es necesaria para desplegar Apex en Salesforce, pero no se ha utilizado como único criterio de calidad.

Un test que únicamente ejecuta líneas para aumentar el porcentaje de cobertura puede no comprobar realmente el comportamiento de la aplicación.

Por ese motivo se utilizan `System.assert`, `System.assertEquals` y otras comprobaciones para verificar resultados concretos.

El objetivo es comprobar:

`qué debería ocurrir → ejecutar la operación → comprobar que realmente ocurrió`