# Track II - Evidencias de entrega

Este documento resume las evidencias técnicas de cumplimiento del Track II del proyecto AlquilaVehículo.

| Entregable | Evidencia | Resultado |
|---|---|---|
| Metadata desplegable | Despliegue completo del proyecto desde `force-app/main/default` sobre una scratch org nueva | Correcto |
| Salesforce DX | Creación de scratch org y despliegue mediante Salesforce CLI | Correcto |
| Tests automatizados | Ejecución de `RunLocalTests` durante el despliegue | 73/73 tests superados |
| Calidad del despliegue | 164 componentes desplegados sin errores | 0 errores |
| Seguridad | Permission Set `VRT_AlquilaVehiculo_User` desplegado y asignado al usuario | Correcto |
| Aplicación Lightning | Navegación, Home Page y dashboard verificados en una org limpia | Correcto |
| Consola Operativa | LWC disponible desde la página de Account | Correcto |
| Aprobaciones | List Views y elementos asociados al proceso de aprobación desplegados | Correcto |

## Validación final

El proyecto fue desplegado desde el repositorio en una scratch org nueva utilizando Salesforce DX.

Resultado del despliegue:

- componentes desplegados: 164
- tests ejecutados: 73
- tests superados: 73
- tests fallidos: 0
- errores de componentes: 0
- estado final: `Succeeded`

La validación confirma que el proyecto puede reconstruirse desde el código fuente y la metadata almacenados en Git, sin depender de la org utilizada durante el desarrollo.