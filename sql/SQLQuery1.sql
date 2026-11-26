--etl datamart final--
USE datamartDGprueba;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Ejecutar_ETL_Diario
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        -- PASO 1: LIMPIEZA DE TABLAS Y RESEED DE IDENTITY
        DELETE FROM dbo.fact_ventas;
        DELETE FROM dbo.dim_producto;
        IF @@ROWCOUNT <> 0
            DBCC CHECKIDENT ('dbo.dim_producto', RESEED, 0);
        DELETE FROM dbo.dim_cliente;
        IF @@ROWCOUNT <> 0
            DBCC CHECKIDENT ('dbo.dim_cliente', RESEED, 0);
        DELETE FROM dbo.dim_vendedor;
        IF @@ROWCOUNT <> 0
           DBCC CHECKIDENT ('dbo.dim_vendedor', RESEED, 0);
        DELETE FROM dbo.dim_ubicacion;
        IF @@ROWCOUNT <> 0
            DBCC CHECKIDENT ('dbo.dim_ubicacion', RESEED, 0);
        DELETE FROM dbo.dim_tiempo;
       
        -- 1. DIMENSION TIEMPO
        INSERT INTO dbo.dim_tiempo (
            fecha,
            anio,
            mes,
            diaMes,
            diaSemana,
            trimestre
        )
        SELECT DISTINCT
            v.fecha,
            CAST(YEAR(v.fecha) AS SMALLINT),
            CAST(MONTH(v.fecha) AS SMALLINT),
            CAST(DAY(v.fecha) AS SMALLINT),
            UPPER(LTRIM(RTRIM(DATENAME(WEEKDAY, v.fecha)))),
            CAST(DATEPART(QUARTER, v.fecha) AS SMALLINT)
        FROM DoñaGumi.dbo.Ventas v
        WHERE v.fecha IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.dim_tiempo t
              WHERE t.fecha = v.fecha
          );

        -- 2. DIMENSION CLIENTE
        INSERT INTO dbo.dim_cliente (
            pk_cliente,
            nombre,
            id_distrito,
            id_zona
        )
        SELECT DISTINCT
            CAST(LTRIM(RTRIM(c.id_cliente)) AS CHAR(10)),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(c.nombre_cliente)), ''), 'SIN NOMBRE')),
            NULLIF(LTRIM(RTRIM(z.id_distrito)), ''),
            NULLIF(LTRIM(RTRIM(c.id_zona)), '')
        FROM DoñaGumi.dbo.Clientes c
        LEFT JOIN DoñaGumi.dbo.Zonas z
            ON LTRIM(RTRIM(c.id_zona)) = LTRIM(RTRIM(z.id_zona))
        WHERE NULLIF(LTRIM(RTRIM(c.id_cliente)), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.dim_cliente dc
              WHERE LTRIM(RTRIM(dc.pk_cliente)) = LTRIM(RTRIM(c.id_cliente))
          );

        -- 3. DIMENSION PRODUCTO

        INSERT INTO dbo.dim_producto (
            pk_producto,
            nombre_producto,
            categoria
        )
        SELECT DISTINCT
            LTRIM(RTRIM(p.id_producto)),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(p.nombre_producto)), ''), 'SIN PRODUCTO')),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(cat.nombre_categoria)), ''), 'SIN CATEGORIA'))
        FROM DoñaGumi.dbo.productos p
        LEFT JOIN DoñaGumi.dbo.Categorias cat
            ON p.id_categoria = cat.id_categoria
        WHERE NULLIF(LTRIM(RTRIM(p.id_producto)), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.dim_producto dp
              WHERE LTRIM(RTRIM(dp.pk_producto)) = LTRIM(RTRIM(p.id_producto))
          );

        -- 4. DIMENSION VENDEDOR
        INSERT INTO dbo.dim_vendedor (
            pk_vendedor,
            nombre,
            canal
        )
        SELECT DISTINCT
            LTRIM(RTRIM(vd.id_vendedor)),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(vd.nombre)), ''), 'SIN VENDEDOR')),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(vd.canal)), ''), 'SIN CANAL'))
        FROM DoñaGumi.dbo.Vendedores vd
        WHERE NULLIF(LTRIM(RTRIM(vd.id_vendedor)), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.dim_vendedor dv
              WHERE LTRIM(RTRIM(dv.pk_vendedor)) = LTRIM(RTRIM(vd.id_vendedor))
          );
    -- 5. DIMENSION UBICACION
        INSERT INTO dbo.dim_ubicacion (
            pk_zona,
            distrito,
            zona,
            mercado
        )
        SELECT DISTINCT
            LTRIM(RTRIM(z.id_zona)),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(d.nombre_distrito)), ''), 'SIN DISTRITO')),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(z.nombre_zona)), ''), 'SIN ZONA')),
            UPPER(ISNULL(NULLIF(LTRIM(RTRIM(mkt.nombre_mercado)), ''), 'SIN MERCADO'))
        FROM DoñaGumi.dbo.Zonas z
        LEFT JOIN DoñaGumi.dbo.Distritos d
            ON LTRIM(RTRIM(z.id_distrito)) = LTRIM(RTRIM(d.id_distrito))
        OUTER APPLY (
            SELECT TOP 1 m.nombre_mercado
            FROM DoñaGumi.dbo.Mercados m
            WHERE LTRIM(RTRIM(m.id_distrito)) = LTRIM(RTRIM(z.id_distrito))
            ORDER BY m.id_mercado
        ) mkt
        WHERE NULLIF(LTRIM(RTRIM(z.id_zona)), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.dim_ubicacion du
              WHERE LTRIM(RTRIM(du.pk_zona)) = LTRIM(RTRIM(z.id_zona))
          );

        -- 6. TABLA DE HECHOS: FACT_VENTAS

        INSERT INTO dbo.fact_ventas (
            id_cliente,
            id_producto,
            id_vendedor,
            fecha,
            id_ubicacion,
            cantidad,
            precio_unitario,
            precio_mayor,
            total
        )
        SELECT DISTINCT
            dc.id_cliente,
            dp.id_producto,
            dv.id_vendedor,
            v.fecha,
            du.id_ubicacion,
            dtv.cantidad_entregada,
            ISNULL(dtv.precio_unitario, 0),
            ISNULL(dtv.precio_mayor, 0),
            ISNULL(dtv.subtotal, 0)
        FROM DoñaGumi.dbo.Ventas v
        INNER JOIN DoñaGumi.dbo.DetalleVentas dtv
            ON LTRIM(RTRIM(v.id_venta)) = LTRIM(RTRIM(dtv.id_venta))
        INNER JOIN dbo.dim_cliente dc
            ON LTRIM(RTRIM(dc.pk_cliente)) = LTRIM(RTRIM(v.id_cliente))
        INNER JOIN dbo.dim_vendedor dv
            ON LTRIM(RTRIM(dv.pk_vendedor)) = LTRIM(RTRIM(v.id_vendedor))
        LEFT JOIN dbo.dim_ubicacion du
            ON LTRIM(RTRIM(du.pk_zona)) = LTRIM(RTRIM(v.id_zona))
        INNER JOIN dbo.dim_producto dp
            ON LTRIM(RTRIM(dp.pk_producto)) = LTRIM(RTRIM(dtv.id_producto))
        WHERE v.fecha IS NOT NULL
          AND dtv.cantidad_entregada > 0
          AND ISNULL(dtv.precio_unitario, 0) >= 0
          AND ISNULL(dtv.precio_mayor, 0) >= 0
          AND ISNULL(dtv.subtotal, 0) >= 0
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.fact_ventas f
              WHERE f.id_cliente = dc.id_cliente
                AND f.id_producto = dp.id_producto
                AND f.id_vendedor = dv.id_vendedor
                AND f.fecha = v.fecha
                AND ISNULL(f.id_ubicacion, -1) = ISNULL(du.id_ubicacion, -1)
                AND f.cantidad = dtv.cantidad_entregada
                AND f.total = ISNULL(dtv.subtotal, 0)
          );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO