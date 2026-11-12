SELECT
    fecha,
    CAST(ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS DECIMAL(6, 2)) AS duracion_promedio_minutos
FROM entregas_db.entregas
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
