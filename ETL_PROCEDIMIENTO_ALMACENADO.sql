SELECT v.canal, SUM(f.total) AS total_ventas
FROM fact_ventas f
JOIN dim_vendedor v ON f.id_vendedor = v.id_vendedor
GROUP BY v.canal;