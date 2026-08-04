# AlquilaVehículo

**Salesforce DX Project | Apex | Lightning Web Components | Platform Developer I**

Aplicación desarrollada sobre Salesforce para la gestión del alquiler de vehículos. Este proyecto tiene como objetivo aplicar buenas prácticas de desarrollo profesional mediante la implementación de una arquitectura escalable, código mantenible y un flujo de trabajo basado en Git.

El desarrollo se ha realizado como parte de mi proceso de aprendizaje y preparación para la certificación **Salesforce Platform Developer I**, priorizando la calidad del código, la separación de responsabilidades y las recomendaciones de Salesforce para el desarrollo sobre la plataforma.

> **Estado del proyecto:** En desarrollo activo. Se continúan incorporando nuevas funcionalidades y mejoras.

---

# Tecnologías

* Salesforce DX
* Apex
* Lightning Web Components (LWC)
* SOQL / SOSL
* Apex Triggers
* Queueable Apex
* Custom Metadata Types
* Visual Studio Code
* Git y GitHub

---

# Objetivos

El propósito de este proyecto es desarrollar una aplicación de gestión de alquiler de vehículos aplicando prácticas utilizadas en proyectos profesionales de Salesforce.

Entre los objetivos principales se encuentran:

* Diseñar una arquitectura mantenible y escalable.
* Aplicar principios de desarrollo orientados a buenas prácticas.
* Implementar lógica de negocio mediante Apex.
* Desarrollar componentes Lightning Web Components.
* Utilizar programación asíncrona cuando el proceso lo requiera.
* Configurar reglas de negocio mediante Custom Metadata.
* Garantizar la calidad mediante pruebas unitarias.
* Gestionar el desarrollo utilizando Git y Pull Requests.

---

# Arquitectura

El proyecto sigue una arquitectura basada en la separación de responsabilidades.

* Trigger → Punto de entrada de la lógica.
* Trigger Handler → Gestión de eventos del Trigger.
* Service Layer → Implementación de la lógica de negocio.
* Custom Metadata → Configuración desacoplada del código.
* Queueable Apex → Procesamiento asíncrono.
* Apex Tests → Validación automática del comportamiento de la aplicación.

Este enfoque facilita el mantenimiento del código, mejora la reutilización de componentes y favorece la escalabilidad de la solución.

---

# Funcionalidades

Actualmente el proyecto incluye funcionalidades relacionadas con la gestión del alquiler de vehículos.

Entre ellas se encuentran:

* Gestión de vehículos.
* Gestión de alquileres.
* Validaciones de negocio mediante Apex.
* Cálculo automático de precios.
* Motor de precios configurable mediante Custom Metadata.
* Generación de facturas.
* Procesamiento asíncrono mediante Queueable Apex.
* Registro de procesos.
* Pruebas unitarias.

El proyecto continúa evolucionando con nuevas funcionalidades y mejoras.

---

# Estado del desarrollo

El desarrollo sigue un flujo de trabajo basado en ramas de características (Feature Branches) y Pull Requests antes de integrar los cambios en la rama principal.

Las próximas mejoras incluyen:

* Ampliación de funcionalidades.
* Documentación técnica completa.
* Diagramas de arquitectura.
* Capturas de la aplicación.
* Mejoras en la cobertura de pruebas.
* Optimización y refactorización del código.

---

# Buenas prácticas aplicadas

Durante el desarrollo se han aplicado, entre otras, las siguientes prácticas:

* Arquitectura por capas.
* Separación de responsabilidades.
* Código bulkificado.
* Uso eficiente de colecciones (List, Set y Map).
* Minimización de consultas SOQL y operaciones DML.
* Programación asíncrona.
* Configuración desacoplada mediante Custom Metadata.
* Pruebas unitarias.
* Control de versiones con Git y GitHub.

---

# Estructura del proyecto

```text
force-app/
 └── main/
      └── default/
           ├── classes/
           ├── lwc/
           ├── objects/
           ├── triggers/
           ├── customMetadata/
           └── ...
```

---

# Documentación

La documentación técnica del proyecto se irá incorporando progresivamente en la carpeta `docs`, incluyendo:

* Arquitectura.
* Decisiones de diseño.
* Casos de uso.
* Diagramas.
* Guías de despliegue.
* Evolución del proyecto.

---

# Autor

**Luis Javier Gómez Hernández**

Salesforce Platform Developer I

GitHub: https://github.com/lgomez-h

LinkedIn: https://www.linkedin.com/in/luis-javier-gomez-hernandez/
