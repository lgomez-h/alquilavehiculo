# Seguridad

## 1. Objetivo

La seguridad de AlquilaVehículo intenta seguir el principio de mínimo privilegio: un usuario debe disponer de los permisos necesarios para realizar su trabajo, pero no recibir acceso adicional simplemente para conseguir que la aplicación funcione.

Para ello se combinan diferentes mecanismos de Salesforce:

- permisos sobre objetos;
- permisos sobre campos;
- acceso a clases Apex;
- reglas de acceso a registros;
- comprobaciones de seguridad desde Apex.

## 2. Permission Set operativo

Se creó el Permission Set:

`VRT_AlquilaVehiculo_User`

Este Permission Set representa los permisos necesarios para un usuario operativo de AlquilaVehículo.

Se decidió utilizar un Permission Set específico en lugar de asumir que el usuario tendrá permisos de administrador.

Esto también facilita el despliegue de la aplicación en otra org, ya que los permisos necesarios forman parte de la metadata del proyecto.

## 3. Permisos sobre objetos

El Permission Set proporciona diferentes niveles de acceso dependiendo de la función de cada objeto.

### Account

El usuario dispone de acceso de lectura.

La Consola Operativa se utiliza desde una cuenta, pero no necesita proporcionar permisos generales para modificar las cuentas.

### VRT_Rental__c

El usuario puede:

- leer;
- crear;
- editar.

No dispone de permiso general para eliminar alquileres.

Esto permite utilizar la Consola Operativa y trabajar con el ciclo de vida de los alquileres sin proporcionar más permisos de los necesarios.

### VRT_Vehicle__c

El usuario puede:

- leer;
- crear;
- editar.

No dispone de permiso general para eliminar vehículos.

### VRT_Invoice__c

El usuario dispone de acceso de lectura.

Las facturas son creadas por el proceso automático de facturación, por lo que el usuario operativo no necesita permiso general para crearlas o modificarlas manualmente.

### VRT_ProcessLog__c

El usuario dispone de acceso de lectura.

Los logs son generados por los procesos de la aplicación y su función principal para el usuario es permitir consultar el resultado de esas ejecuciones.

## 4. Permisos sobre campos

Además de controlar el acceso a los objetos, el Permission Set diferencia qué campos pueden ser modificados.

Por ejemplo, en `VRT_Rental__c` el usuario puede editar datos necesarios para trabajar con el alquiler, como las fechas, la cuenta, el vehículo o las notas.

Otros campos son únicamente de lectura porque su valor es calculado o controlado por la aplicación.

Entre ellos se encuentran:

- coste total;
- duración;
- estado de aprobación;
- importe aprobado;
- motivo de rechazo.

En `VRT_Vehicle__c` ocurre algo parecido.

El usuario puede editar información operativa como kilometraje, fecha de fabricación, modelo o color, mientras que determinados campos gestionados por la lógica de la aplicación permanecen únicamente como lectura.

La intención es evitar que un usuario modifique manualmente valores que deberían ser resultado de las reglas de negocio.

## 5. Acceso a Apex

Los componentes LWC necesitan permiso para ejecutar las clases Apex que utilizan.

El Permission Set proporciona acceso a:

- `VRT_CLS_RentalConsoleController`
- `VRT_CLS_VehicleSearchService`

Estas son las clases utilizadas directamente como puntos de entrada desde los componentes LWC.

No es necesario proporcionar acceso directo al usuario a todas las clases internas utilizadas posteriormente por los Services y automatizaciones.

## 6. Acceso a registros

Los permisos sobre objetos indican qué operaciones puede realizar un usuario sobre un tipo de registro, pero no significan necesariamente que pueda acceder a todos los registros existentes.

Por ejemplo:

`Read sobre VRT_Rental__c`

significa que el usuario tiene permiso para leer alquileres, pero las reglas de sharing siguen determinando a qué alquileres concretos puede acceder.

Por este motivo se mantienen desactivados permisos generales como:

- `View All`
- `Modify All`

La intención es no resolver los problemas de acceso proporcionando acceso completo a todos los registros.

## 7. Seguridad desde Apex

Los puntos de entrada utilizados por la interfaz aplican también controles desde Apex.

El Controller de la Consola Operativa utiliza:

`with sharing`

para respetar las reglas de acceso a registros del usuario.

El Buscador Global también comprueba el acceso al objeto y utiliza:

`Security.stripInaccessible()`

antes de devolver los resultados al LWC.

`Security.stripInaccessible()` permite eliminar de los registros aquellos campos a los que el usuario no tenga acceso.

De esta forma, la búsqueda no debe devolver información simplemente porque Apex haya podido recuperarla internamente.

## 8. Campos calculados y procesos automáticos

Algunos campos no necesitan ser editables para el usuario porque son gestionados automáticamente por la aplicación.

Por ejemplo:

- el coste total procede del Pricing Engine;
- determinados datos de aprobación proceden del proceso financiero;
- las facturas se crean mediante el proceso asíncrono;
- los logs se generan durante la ejecución de los procesos.

Dar permiso de edición manual sobre estos valores podría permitir que el usuario dejara los datos en un estado incoherente con las reglas de negocio.

## 9. Principio aplicado

La idea general utilizada durante la revisión de seguridad puede resumirse así:

`dar los permisos necesarios, no todos los permisos posibles`

El objetivo no es impedir que el usuario trabaje, sino identificar qué necesita realmente para utilizar AlquilaVehículo y conceder únicamente ese acceso.

La configuración exacta del Permission Set forma parte de la metadata del proyecto:

`force-app/main/default/permissionsets/VRT_AlquilaVehiculo_User.permissionset-meta.xml`