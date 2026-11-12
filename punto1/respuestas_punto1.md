# Respuestas: punto 1 (ventas diarias con control de actualidad)

Autor: Tomás Avendaño Parra

## 1. ¿Por qué usar _loaded_at y no fecha_venta para este control?

Porque loaded_at es un metadato, que explica cuándo llegó la venta al sistema, no cuándo ocurrió. En este caso, el control quería detectar si la carga de los datos se retrasó, no la venta como tal, por lo que debe medir la llegada. En los 3 escenarios que se corrieron, los datos del negocio eran idénticos en términos de las fechas de compra, sin embargo, cambió loaded_at para evaluar freshness.

## 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Porque los datos viejos pueden estar correctos y pasar todo. Las pruebas como unique, not_null, valores_ventas solo revisan que el contenido existe, pero no cuando llegaron. En este caso, en el escenario desactualizado, los registros que detectó freshness con carga de más de 30h pasaron las 19 pruebas previas.
