-- 1. Los seis registros del 3 de octubre
SELECT id_envio, ciudad, transportadora, estado, duracion_minutos, fecha
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio;

-- 2. Conteo por estado del 3 de octubre
SELECT fecha, estado, COUNT(*) AS total_intentos
FROM entregas_db.entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado;

-- 3. Total de registros de la tabla
SELECT COUNT(*) AS total_registros
FROM entregas_db.entregas;
