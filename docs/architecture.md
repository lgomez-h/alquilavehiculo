# Arquitectura de AlquilaVehículo

## 1. Objetivo

AlquilaVehículo es una aplicación desarrollada sobre Salesforce para gestionar el ciclo de alquiler de vehículos.

El Track II amplía la aplicación incorporando automatización de precios, control de disponibilidad, aprobaciones financieras, una consola operativa Lightning, facturación asíncrona y búsqueda global de flota.

La arquitectura se ha diseñado siguiendo principalmente estos criterios:

- separación de responsabilidades;
- reutilización de la lógica de negocio;
- procesamiento bulkificado;
- seguridad;
- testabilidad;
- uso de funcionalidades estándar de Salesforce cuando resulta apropiado.

---

## 2. Arquitectura general

La aplicación utiliza dos flujos principales de ejecución.

### Interacción desde Lightning Web Components

```text
LWC
 ↓
Apex Controller
 ↓
Service
```

### Automatización sobre registros

```text
Trigger
 ↓
Trigger Handler
 ↓
Service
```

Esta separación permite que la interfaz de usuario y las automatizaciones utilicen lógica de negocio centralizada sin duplicarla.

### Lightning Web Components

Los LWC son responsables de la presentación y de la interacción con el usuario.

Cuando necesitan consultar información o ejecutar lógica de negocio en servidor, utilizan métodos Apex expuestos mediante Controllers.

La lógica crítica no depende exclusivamente del cliente, ya que las reglas de negocio deben cumplirse también cuando los registros se crean o modifican desde otros puntos de entrada.

### Controllers

Los Apex Controllers actúan como punto de entrada entre los LWC y la capa de negocio.

Sus responsabilidades principales son:

- recibir las peticiones del componente;
- validar el contexto necesario;
- aplicar controles de seguridad;
- delegar la lógica de negocio en los Services;
- devolver al LWC únicamente la información necesaria.

### Trigger y Trigger Handler

`VRT_TRG_Rental` centraliza la automatización asociada al objeto de alquiler.

El Trigger delega su ejecución en `VRT_TRG_RentalHandler`, evitando introducir lógica de negocio directamente en el Trigger.

Esto permite separar el contexto de ejecución de Salesforce de la lógica que debe aplicarse a los alquileres.

### Services

Los Services contienen la lógica de negocio reutilizable.

Esta capa permite que una misma regla pueda ser utilizada desde diferentes puntos de entrada y facilita tanto el mantenimiento como las pruebas unitarias.

---

## 3. Principales decisiones de arquitectura

### 3.1 Pricing configurable mediante Custom Metadata

Las tarifas de alquiler se almacenan en `VRT_PricingRule__mdt` en lugar de estar codificadas directamente en Apex.

`VRT_CLS_PricingService` aplica las reglas necesarias para calcular el precio del alquiler, incluyendo temporada, duración, fidelidad del cliente y posibles penalizaciones.

La utilización de Custom Metadata permite modificar la configuración de precios sin tener que modificar y volver a desplegar código Apex.

---

### 3.2 Disponibilidad validada en servidor

La disponibilidad de los vehículos se valida en Apex antes de guardar un alquiler.

La regla impide que un mismo vehículo tenga alquileres activos con fechas solapadas.

La lógica está diseñada para trabajar con colecciones de registros, utilizando Lists, Sets y Maps y evitando consultas SOQL dentro de bucles.

Mantener esta validación en servidor garantiza que la regla se aplique independientemente del origen de la operación.

---

### 3.3 Control financiero mediante Approval Process

Los alquileres que superan los límites económicos definidos utilizan Approval Process de Salesforce.

La solución combina funcionalidad estándar de la plataforma con Apex para implementar las reglas adicionales necesarias.

Esta decisión permite aprovechar mecanismos nativos de Salesforce como:

- aprobación y rechazo;
- bloqueo del registro;
- trazabilidad del proceso;
- diferentes niveles de aprobación.

De esta forma se evita desarrollar mediante código funcionalidades que la plataforma ya proporciona.

---

### 3.4 Consola Operativa mediante LWC

La Consola Operativa se integra en la página de Account mediante Lightning Web Components.

Su arquitectura sigue el patrón:

```text
LWC → Controller → Service
```

Desde la consola se puede consultar y gestionar información relacionada con los alquileres del cliente sin abandonar su página.

El componente proporciona una experiencia interactiva al usuario, mientras que las reglas críticas, como pricing y disponibilidad, permanecen centralizadas en servidor.

Esto evita duplicar lógica de negocio en JavaScript y Apex.

---

### 3.5 Facturación asíncrona

Cuando un alquiler alcanza el estado correspondiente de finalización, la generación de la factura se procesa de forma asíncrona.

El flujo principal es:

```text
Trigger
 ↓
Trigger Handler
 ↓
Queueable Apex
 ↓
Invoice Service
```

Queueable Apex permite ejecutar la generación de facturas fuera de la transacción principal del alquiler.

La solución incluye control para evitar facturas duplicadas y registro del resultado del proceso.

Los errores del procesamiento asíncrono pueden gestionarse mediante Finalizer y las notificaciones posteriores se desacoplan mediante Platform Event y Flow.

Esta arquitectura reduce el acoplamiento entre la finalización del alquiler, la creación de la factura y la notificación.

---

### 3.6 Procesamiento periódico

Las operaciones que pueden afectar a un volumen elevado de registros utilizan Batch Apex.

Scheduled Apex permite programar su ejecución periódica.

La separación entre ambos mecanismos diferencia:

```text
Scheduled Apex → cuándo ejecutar
Batch Apex     → qué procesar
```

Esto permite procesar grandes volúmenes respetando los límites de ejecución de Salesforce.

---

### 3.7 Búsqueda global de flota

La búsqueda de vehículos se implementa separando la interfaz Lightning de la lógica ejecutada en servidor.

El componente LWC gestiona los criterios introducidos por el usuario y Apex realiza la búsqueda y devuelve únicamente los datos necesarios.

Esta separación mantiene la lógica de acceso a datos en servidor y evita exponer información de forma innecesaria al cliente.

---

## 4. Seguridad y calidad

La seguridad forma parte de la arquitectura y no únicamente de la interfaz.

Entre las medidas utilizadas se encuentran:

- `with sharing` cuando corresponde;
- comprobaciones CRUD/FLS en operaciones expuestas desde LWC;
- `Security.stripInaccessible()` cuando es necesario;
- exposición controlada de datos desde los Controllers;
- Permission Set `VRT_AlquilaVehiculo_User` para centralizar los permisos funcionales de la aplicación.

La lógica se ha diseñado además siguiendo criterios de bulkificación:

- uso de Lists, Sets y Maps;
- procesamiento conjunto de registros;
- evitar SOQL dentro de bucles;
- evitar DML innecesario dentro de bucles;
- separación de la lógica en Services.

Esta estructura facilita las pruebas unitarias y permite validar las reglas de negocio independientemente de la interfaz de usuario.

---

## 5. Resumen de decisiones

Las principales decisiones arquitectónicas de AlquilaVehículo son:

1. Separar presentación, entrada Apex y negocio mediante `LWC → Controller → Service`.
2. Separar automatización y negocio mediante `Trigger → Handler → Service`.
3. Centralizar la lógica reutilizable en Services.
4. Utilizar Custom Metadata para configurar las tarifas.
5. Mantener las validaciones críticas de negocio en servidor.
6. Utilizar Approval Process para aprovechar las capacidades estándar de Salesforce.
7. Utilizar Queueable Apex para desacoplar la facturación de la transacción principal.
8. Utilizar Platform Events y Flow para desacoplar las notificaciones.
9. Utilizar Batch y Scheduled Apex para procesamiento periódico.
10. Diseñar la lógica Apex para funcionar correctamente con múltiples registros.
11. Aplicar controles de sharing, CRUD y FLS en los puntos de acceso correspondientes.
12. Centralizar los permisos funcionales mediante `VRT_AlquilaVehiculo_User`.

El objetivo de estas decisiones es mantener una aplicación modular, configurable y mantenible, aprovechando las capacidades nativas de Salesforce y evitando concentrar la lógica de negocio en los componentes de interfaz o en los Triggers.