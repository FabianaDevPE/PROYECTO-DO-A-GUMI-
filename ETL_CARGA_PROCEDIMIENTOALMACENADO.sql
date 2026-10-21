USE datamartDGprueba;
GO

CREATE OR ALTER PROCEDURE sp_Ejecutar_ETL_Diario
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Dimensión Tiempo
    INSERT INTO dim_tiempo(
        fecha,
        anio,
        mes,
        diaMes,
        diaSemana,
        trimestre
    )
    SELECT DISTINCT
        fecha,
        YEAR(fecha),
        MONTH(fecha),
        DAY(fecha),
        DATENAME(WEEKDAY, fecha),
        DATEPART(QUARTER, fecha)
    FROM DoñaGumi.dbo.Ventas v
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_tiempo t WHERE t.fecha = v.fecha
    );

    -- 2. Dimensión Cliente
    INSERT INTO dim_cliente (
        pk_cliente,
        nombre,
        id_distrito,
        id_zona
    )
    SELECT DISTINCT
        RTRIM(c.id_cliente),
        c.nombre_cliente,
        z.id_distrito,
        c.id_zona
    FROM DoñaGumi.dbo.Clientes c
    INNER JOIN DoñaGumi.dbo.Zonas z
        ON c.id_zona = z.id_zona
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dim_cliente dc 
        WHERE RTRIM(dc.pk_cliente) = RTRIM(c.id_cliente)
    );

    -- 3. Dimensión Producto
    INSERT INTO dim_producto(
        pk_producto,
        nombre_producto,
        categoria
    )
    SELECT DISTINCT
        p.id_producto,
        p.nombre_producto,
        c.nombre_categoria
    FROM DoñaGumi.dbo.Productos p
    INNER JOIN DoñaGumi.dbo.Categorias c
        ON p.id_categoria = c.id_categoria
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_producto dp WHERE dp.pk_producto = p.id_producto
    );

    -- 4. Dimensión Vendedor
    INSERT INTO dim_vendedor(
        pk_vendedor,
        nombre,
        canal
    )
    SELECT DISTINCT
        id_vendedor,
        nombre,
        canal
    FROM DoñaGumi.dbo.Vendedores v
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_vendedor dv WHERE dv.pk_vendedor = v.id_vendedor
    );

    -- 5. Dimensión Ubicación (Sin Row_Number)
    INSERT INTO dim_ubicacion(
        pk_zona,
        distrito,
        zona,
        mercado
    )
    SELECT DISTINCT
        z.id_zona,
        d.nombre_distrito,
        z.nombre_zona,
        m.nombre_mercado
    FROM DoñaGumi.dbo.Zonas z
    INNER JOIN DoñaGumi.dbo.Distritos d
        ON z.id_distrito = d.id_distrito
    LEFT JOIN DoñaGumi.dbo.Mercados m
        ON d.id_distrito = m.id_distrito
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_ubicacion du WHERE du.pk_zona = z.id_zona
    );

    -- 6. Tabla de Hechos (Fact Ventas) 
    INSERT INTO fact_ventas(
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
        dtv.precio_unitario,
        dtv.precio_mayor,
        dtv.subtotal
    FROM DoñaGumi.dbo.Ventas v
    INNER JOIN DoñaGumi.dbo.DetalleVentas dtv
        ON v.id_venta = dtv.id_venta
    INNER JOIN dim_cliente dc
        ON RTRIM(dc.pk_cliente) = RTRIM(v.id_cliente)
    INNER JOIN dim_vendedor dv
        ON RTRIM(dv.pk_vendedor) = RTRIM(v.id_vendedor)
    LEFT JOIN dim_ubicacion du
        ON RTRIM(du.pk_zona) = RTRIM(v.id_zona)
    INNER JOIN dim_producto dp
        ON RTRIM(dp.pk_producto) = RTRIM(dtv.id_producto)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM fact_ventas f
        WHERE f.id_cliente = dc.id_cliente
          AND f.id_producto = dp.id_producto
          AND f.id_vendedor = dv.id_vendedor
          AND f.fecha = v.fecha
          AND ISNULL(f.id_ubicacion, -1) = ISNULL(du.id_ubicacion, -1)
          AND f.cantidad = dtv.cantidad_entregada
          AND f.total = dtv.subtotal
    );

END
GO

EXEC sp_Ejecutar_ETL_Diario