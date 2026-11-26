# Sistema de Inteligencia de Negocios, BI y Big Data — Doña Gumi

* **Curso:** Base de Datos Avanzadas y Big Data
* **Institución:** Universidad Privada del Norte (UPN)
* **Periodo Lectivo:** 2026-2
* **Empresa / Caso de Estudio:** Doña Gumi

---

## 📌 Descripción del Proyecto

Solución integral de arquitectura y análisis de datos orientada a centralizar la información comercial y logística de **Doña Gumi**, mejorar la trazabilidad operativa y optimizar la toma de decisiones. El sistema integra una base de datos relacional y un Data Mart dimensional (`datamartDGprueba`) en SQL Server, procesos ETL de limpieza y carga, procesamiento distribuido con Delta Lake en **Databricks (Unity Catalog)** y tableros ejecutivos interactivos en **Power BI**.

---

## 🛠️ Requisitos Previos y Dependencias

Para desplegar, reproducir o validar la solución se requieren las siguientes herramientas:

* **Motor Relacional y Data Mart:** Microsoft SQL Server + SQL Server Management Studio (SSMS).
* **Entorno Big Data:** Databricks con soporte para Unity Catalog, PySpark, Delta Lake y SQL.
* **Explotación Analítica:** Power BI Desktop.
* **Control de Versiones y Documentación:** Git / GitHub y archivos de soporte (`.docx`, `.pdf`, `.jpeg`).

---

## 💡 Decisiones de Negocio, Conclusiones y Recomendaciones

### 🎯 Decisiones Estratégicas de Negocio
1. **Seguimiento de Cobertura y Ventas en Power BI:** El monitoreo continuo de indicadores clave (Venta Neta Real, % Cobertura y Cantidad Entregada) con segmentación por distrito y categoría permite priorizar zonas de mayor rotación y detectar oportunidades de expansión comercial.
2. **Estandarización de Datos Geográficos y Operativos:** La depuración y consolidación de dimensiones (`dim_ubicacion` y tablas maestras) elimina inconsistencias por codificación o duplicidad y asegura reportes confiables.
3. **Control de Calidad y Trazabilidad por Evidencias:** La validación sistemática mediante matriz de verificación (`E-02` a `E-14`) garantiza que cada entregable técnico cumpla los criterios funcionales y de rendimiento definidos.

### 📌 Conclusiones Técnicas y Operativas
* **Modelado Dimensional Eficiente:** La implementación del esquema en estrella (`fact_ventas` y dimensiones vinculadas) reduce la latencia en consultas analíticas de agregación frente al esquema transaccional.
* **Procesamiento Distribuido en Databricks:** La ingesta desde volúmenes con codificación `ISO-8859-1` y la persistencia en tablas Delta (`dataframe_UBICACION`) permiten ejecutar consultas SQL rápidas y mantener integridad transaccional.
* **Estructura Modular del Repositorio:** Separar los scripts SQL, el flujo de Databricks, los reportes de Power BI, la documentación y las evidencias facilita el mantenimiento y la auditoría técnica del proyecto.

### 🚀 Recomendaciones para la Continuidad
* **Automatización de Cargas y Pipelines:** Programar la ejecución periódica de los flujos ETL y de los Workflows en Databricks con alertas automáticas ante fallos de calidad.
* **Mantenimiento de Tablas Delta:** Aplicar compactación (`OPTIMIZE`) y auditorías periódicas de historial conforme aumente el volumen histórico de transacciones.

---

## 📁 Estructura del Repositorio

```text
PROYECTO-DO-A-GUMI-/
├── README.md                           # Guía técnica y documentación principal del proyecto
├── bi/
│   └── dashboard_donagumi.pbix         # Dashboard interactivo ejecutado en Power BI
├── databricks/
│   ├── 01_ingesta_ubicacion.py         # Ingesta desde Volume (ISO-8859-1) y guardado en Delta
│   ├── 02_consultas_ubicacion.sql      # Consultas SQL analíticas y auditoría de datos
│   └── config_bigdata.yaml             # Parámetros de catálogo, esquema, volumen y tablas
├── docs/
│   ├── Procedimiento_ETL.docx          # Documentación detallada del flujo ETL
│   ├── T2_Dona_Gumi.pdf                # Informe técnico / entregable T2
│   └── Trabajo_Base_de_Datos.pdf       # Documentación del diseño de base de datos
├── evidencias/
│   ├── reunion_01.jpeg                 # Evidencia visual de coordinación y avance 1
│   └── reunion_02.jpeg                 # Evidencia visual de coordinación y avance 2
└── sql/
    ├── 01_bd_donagumi.sql              # DDL/DML: Base de datos y tablas operativas base
    ├── 02_crear_datamart.sql           # DDL: Creación del Data Mart (datamartDGprueba)
    ├── 03_etl_limpieza.sql             # T-SQL: Depuración y estandarización de registros
    ├── 04_etl_carga_final.sql          # T-SQL: Carga final hacia hechos y dimensiones
    └── 05_vaciar_datamart.sql          # T-SQL: Reinicio y limpieza controlada del Data Mart
