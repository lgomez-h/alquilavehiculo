# Despliegue de AlquilaVehículo

## 1. Requisitos previos

Para desplegar el proyecto se necesita:

- Git
- Salesforce CLI
- una org Salesforce compatible
- permisos para desplegar metadata

El proyecto utiliza Salesforce DX y su metadata principal se encuentra en:

`force-app/main/default`

## 2. Obtener el proyecto

Clonar el repositorio y acceder al directorio:

`git clone <URL_DEL_REPOSITORIO>`

`cd alquilavehiculo`

## 3. Autenticar la org

Autorizar Salesforce CLI contra la org de destino y asignarle un alias.

Ejemplo:

`sf org login web --alias <alias-org>`

## 4. Validar y desplegar

Antes del despliegue definitivo se recomienda realizar una validación:

`sf project deploy start --source-dir force-app --target-org <alias-org> --dry-run --test-level RunLocalTests --wait 30`

En la validación final del proyecto se ejecutaron 73 tests Apex:

- Passing: 73
- Failing: 0

Después puede realizarse el despliegue:

`sf project deploy start --source-dir force-app --target-org <alias-org> --test-level RunLocalTests --wait 30`

## 5. Asignar permisos

El proyecto incluye el Permission Set:

`VRT_AlquilaVehiculo_User`

El despliegue crea el Permission Set, pero no lo asigna automáticamente al usuario.

Después del despliegue debe ejecutarse:

`sf org assign permset --name VRT_AlquilaVehiculo_User --target-org <alias-org>`

Este Permission Set proporciona los permisos operativos necesarios sobre la aplicación, clases Apex, objetos y campos.

Los detalles de seguridad se documentan en `docs/security.md`.

## 6. Configuración dependiente de la org

Después del despliegue deben revisarse los elementos que dependen del entorno:

- reglas de precio de `VRT_PricingRule__mdt`;
- proceso de aprobación financiera y usuarios aprobadores;
- activación de los Flows necesarios;
- configuración de email para las notificaciones;
- programación del Scheduled Apex, si se desea utilizar periódicamente.

La metadata desplegada no incluye los datos de negocio. Los clientes, vehículos y alquileres deben existir o crearse en la org de destino.

## 7. Verificación final

Después del despliegue se recomienda comprobar:

1. La aplicación AlquilaVehículo está disponible.
2. El Permission Set está asignado al usuario.
3. La página de inicio muestra el dashboard y el Buscador Global de Flota.
4. Las pestañas principales de la aplicación están disponibles.
5. Las List Views de aprobación aparecen en Alquileres.
6. La Consola Operativa aparece en la página de Account.
7. Las reglas de precios están disponibles.
8. Los procesos de aprobación, Flows y notificaciones funcionan correctamente.
9. Los tests Apex pasan en la org de destino.

El flujo completo queda resumido en:

`Git → autenticar org → validar → desplegar → asignar permisos → verificar`git status
