SELECT * FROM dim_cliente

SELECT * FROM dim_producto

SELECT * FROM dim_tiempo

SELECT * FROM dim_ubicacion

SELECT * FROM dim_vendedor

SELECT * FROM fact_ventas

-- 1. Eliminar los datos de todas las tablas
DELETE FROM datamartDGprueba.dbo.dim_cliente;
DELETE FROM datamartDGprueba.dbo.dim_producto;
DELETE FROM datamartDGprueba.dbo.dim_ubicacion;
DELETE FROM datamartDGprueba.dbo.dim_vendedor;
DELETE FROM datamartDGprueba.dbo.dim_tiempo;
DELETE FROM datamartDGprueba.dbo.fact_ventas;

-- 2. Reiniciar el valor IDENTITY de cada una de las tablas a 0 
-- (para que el próximo registro comience en 1)
DBCC CHECKIDENT ('datamartDGprueba.dbo.dim_cliente', RESEED, 0);
DBCC CHECKIDENT ('datamartDGprueba.dbo.dim_producto', RESEED, 0);
DBCC CHECKIDENT ('datamartDGprueba.dbo.dim_ubicacion', RESEED, 0);
DBCC CHECKIDENT ('datamartDGprueba.dbo.dim_vendedor', RESEED, 0);
