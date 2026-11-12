# Entrega punto 1: ventas diarias con control de actualidad

Autor: Tomás Avendaño Parra

- `archivos/`: los tres archivos modificados (`dbt/models/ventas_diarias.sql`, `dbt/models/sources.yml`, `airflow/dags/examen_ventas.py`).
- `respuestas_punto1.md`: respuestas a las preguntas conceptuales.
- `evidencias/`:
  - 01-06: build del modelo (PASS=19), resumen, freshness manual y archivos en VS Code/Airflow.
  - 07-12: escenario actualizada. Run `manual__2026-11-12T11:32:52.473507+00:00`: freshness y build en success, logs y resumen antes del bloqueo.
  - 13-18: escenario desactualizada. Run `manual__2026-11-12T11:42:56.941458+00:00`: freshness failed, build upstream_failed, log de freshness (17, texto), motivo `ERROR STALE` y resumen después del bloqueo (mismas 3 filas).
  - 19-21 (opcional): escenario advertencia. Run `manual__2026-11-12T11:52:15.758809+00:00`: WARN y build en success.
