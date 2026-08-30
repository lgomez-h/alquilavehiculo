# Despliegue de AlquilaVehículo

## 1. Objetivo

AlquilaVehículo utiliza una estructura Salesforce DX y mantiene en el repositorio el código y la metadata necesarios para desplegar la aplicación en otra org Salesforce compatible.

El objetivo de este documento es explicar el proceso general de despliegue y distinguir entre:

- elementos incluidos en la metadata;
- configuración que debe realizarse después del despliegue;
- permisos que deben asignarse al usuario.

## 2. Requisitos previos

Para trabajar con el proyecto es necesario disponer de:

- Git;
- Salesforce CLI;
- una org Salesforce compatible;
- permisos suficientes para desplegar metadata en esa org.

También es recomendable utilizar Visual Studio Code con las extensiones de Salesforce para trabajar con el código y la metadata.

## 3. Obtener el proyecto

El primer paso es clonar el repositorio y entrar en su directorio.

Ejemplo:

`git clone <URL_DEL_REPOSITORIO>`

`cd alquilavehiculo`

La estructura principal del proyecto Salesforce se encuentra en:

`force-app/main/default`

Dentro de esta carpeta se almacenan elementos como:

- clases Apex;
- triggers;
- Lightning Web Components;
- objetos y campos;
- Custom Metadata;
- Flows;
- Approval Processes;
- Permission Sets;
- aplicaciones y páginas Lightning.

## 4. Autenticar la org

Antes de desplegar es necesario autorizar Salesforce CLI para trabajar con la org de destino.

Puede utilizarse el mecanismo de autenticación adecuado para el entorno.

Por ejemplo, durante desarrollo puede utilizarse una autenticación mediante navegador y asignar un alias a la org.

Después de la autenticación se puede comprobar la conexión mediante Salesforce CLI antes de iniciar el despliegue.

## 5. Despliegue

Una vez autenticada la org, el contenido del proyecto puede desplegarse desde `force-app`.

Un ejemplo es:

`sf project deploy start --source-dir force-app`

Para una entrega real es recomendable validar primero el despliegue y ejecutar los tests correspondientes antes de aplicar definitivamente los cambios.

Durante la revisión final del proyecto se utilizó:

`sf project deploy start --source-dir force-app --dry-run --test-level RunLocalTests --wait 30`

La validación terminó con:

- Passing: 73
- Failing: 0
- Total: 73

`--dry-run` permite validar el despliegue sin aplicar los cambios.

## 6. Permission Set

El proyecto incluye:

`VRT_AlquilaVehiculo_User`

Después del despliegue, el Permission Set debe asignarse a los usuarios que necesiten utilizar las funcionalidades operativas de AlquilaVehículo.

El despliegue crea la definición del Permission Set, pero no significa que quede automáticamente asignado a todos los usuarios.

Este Permission Set proporciona los permisos necesarios sobre la aplicación, Apex, objetos y campos definidos para el usuario operativo.

Los detalles se encuentran en:

`docs/security.md`

## 7. Datos y configuración de precios

El Pricing Engine utiliza Custom Metadata:

`VRT_PricingRule__mdt`

Las reglas de precio necesarias deben formar parte de la configuración disponible en la org de destino.

El código no utiliza un precio fijo escrito directamente en Apex.

Si no existe una tarifa válida para una combinación necesaria, el Pricing Engine puede impedir que el alquiler continúe con un precio incorrecto.

Por este motivo, después del despliegue debe comprobarse que las reglas de precio necesarias están disponibles.

## 8. Scheduled Apex

El proyecto contiene lógica Scheduled Apex para iniciar periódicamente la revisión de vehículos.

Desplegar una clase que implementa `Schedulable` no crea automáticamente una ejecución programada en la org.

Por tanto, después del despliegue debe configurarse la programación del proceso si se quiere utilizar esta funcionalidad periódicamente.

La separación es:

`Clase desplegada ≠ Job programado`

La clase proporciona qué debe ejecutarse, mientras que la programación de la org determina cuándo debe ejecutarse.

## 9. Approval Process

El proyecto contiene metadata relacionada con el proceso de aprobación financiera.

Después del despliegue debe comprobarse que el proceso está correctamente disponible y que los usuarios que participan en las aprobaciones tienen la configuración y los permisos necesarios en la org de destino.

Los usuarios concretos y la organización de aprobadores pueden depender del entorno donde se despliegue la aplicación.

## 10. Flow y notificaciones

La facturación utiliza un Platform Event y un Flow para iniciar la notificación posterior a la creación de una factura.

El recorrido es:

`InvoiceService`
`→ VRT_InvoiceNotificationEvent__e`
`→ Invoice_Notification_Flow`
`→ notificación`

Después del despliegue debe comprobarse que el Flow se encuentra en el estado necesario para ejecutarse y que la org permite realizar la acción de correo utilizada.

La configuración de email puede variar entre orgs.

## 11. Datos de negocio

El despliegue de metadata no significa que una org nueva vaya a contener automáticamente clientes, vehículos o alquileres de prueba.

Es importante distinguir:

`Metadata`

de:

`Datos`

El repositorio define la estructura y la lógica de la aplicación.

Los registros de negocio utilizados por la aplicación deberán existir o crearse en la org correspondiente.

## 12. Comprobaciones posteriores

Después del despliegue se recomienda comprobar:

1. que la aplicación AlquilaVehículo está disponible;
2. que el Permission Set se ha asignado al usuario correspondiente;
3. que existen las reglas necesarias de Custom Metadata para el Pricing Engine;
4. que el Approval Process está disponible y correctamente configurado;
5. que los Flows necesarios están activos;
6. que la configuración de email permite las notificaciones;
7. que el Scheduled Apex está programado si se desea utilizar;
8. que el usuario puede acceder a los objetos y campos necesarios;
9. que la Consola Operativa aparece en el contexto previsto;
10. que los tests Apex pasan en la org de destino.

## 13. Flujo general

El proceso puede resumirse así:

`Repositorio Git`
`→ clonar proyecto`
`→ autenticar org`
`→ validar despliegue`
`→ desplegar metadata`
`→ asignar Permission Set`
`→ revisar configuración específica de la org`
`→ crear o cargar datos necesarios`
`→ comprobar funcionamiento`

## 14. Consideración sobre portabilidad

El objetivo del proyecto es mantener en Git la mayor cantidad posible de configuración necesaria para reproducir AlquilaVehículo.

Sin embargo, una aplicación Salesforce no depende únicamente de archivos de código.

Existen elementos relacionados con usuarios, permisos, email, jobs programados y configuración propia de cada org que deben revisarse después del despliegue.

Por este motivo, disponer del repositorio completo es necesario para reproducir el proyecto, pero el despliegue debe ir acompañado de las comprobaciones posteriores descritas en este documento.