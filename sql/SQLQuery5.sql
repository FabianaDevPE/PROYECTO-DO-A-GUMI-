use DoñaGumi
GO

CREATE OR ALTER PROCEDURE dbo.sp_cargar_integrar_proveedor
    @ARCHIVO VARCHAR(260) = ''  
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @sql NVARCHAR(MAX);

    IF OBJECT_ID('dbo.stg_proveedor_txt', 'U') IS NULL
        CREATE TABLE dbo.stg_proveedor_txt (linea_raw VARCHAR(MAX));

    TRUNCATE TABLE dbo.stg_proveedor_txt;

    SET @sql = N'BULK INSERT dbo.stg_proveedor_txt ' +
               N'FROM ''' + @ARCHIVO + N''' ' +
               N'WITH (ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, CODEPAGE = ''65001'')';
    EXEC(@sql);

    IF OBJECT_ID('tempdb..#OrigenParseado') IS NOT NULL DROP TABLE #OrigenParseado;

    ;WITH Lineas AS (
        SELECT REPLACE(linea_raw, CHAR(13), '') AS txt
        FROM dbo.stg_proveedor_txt
        WHERE LTRIM(RTRIM(ISNULL(linea_raw, ''))) <> ''
    ),
    P1 AS (
        SELECT
            LTRIM(RTRIM(SUBSTRING(txt, 1, CHARINDEX(' - ', txt) - 1))) AS c1,
            SUBSTRING(txt, CHARINDEX(' - ', txt) + 3, LEN(txt)) AS r1
        FROM Lineas WHERE CHARINDEX(' - ', txt) > 0
    ),
    P2 AS (
        SELECT c1,
            LTRIM(RTRIM(SUBSTRING(r1, 1, CHARINDEX(' - ', r1) - 1))) AS c2,
            SUBSTRING(r1, CHARINDEX(' - ', r1) + 3, LEN(r1)) AS r2
        FROM P1 WHERE CHARINDEX(' - ', r1) > 0
    ),
    P3 AS (
        SELECT c1, c2,
            LTRIM(RTRIM(SUBSTRING(r2, 1, CHARINDEX(' - ', r2) - 1))) AS c3,
            SUBSTRING(r2, CHARINDEX(' - ', r2) + 3, LEN(r2)) AS r3
        FROM P2 WHERE CHARINDEX(' - ', r2) > 0
    ),
    P4 AS (
        SELECT c1, c2, c3,
            LTRIM(RTRIM(SUBSTRING(r3, 1, CHARINDEX(' - ', r3) - 1))) AS c4,
            SUBSTRING(r3, CHARINDEX(' - ', r3) + 3, LEN(r3)) AS r4
        FROM P3 WHERE CHARINDEX(' - ', r3) > 0
    ),
    P5 AS (
        SELECT c1, c2, c3, c4,
            LTRIM(RTRIM(SUBSTRING(r4, 1, CHARINDEX(' - ', r4) - 1))) AS c5,
            LTRIM(RTRIM(SUBSTRING(r4, CHARINDEX(' - ', r4) + 3, LEN(r4)))) AS c6
        FROM P4 WHERE CHARINDEX(' - ', r4) > 0
    ),
    Convertido AS (
        SELECT
            TRY_CAST(c1 AS INT)          AS id_proveedor,
            CAST(c2 AS VARCHAR(100))     AS nombre_proveedor,
            CAST(c3 AS VARCHAR(15))      AS telefono,
            CAST(c4 AS VARCHAR(200))     AS direccion,
            CAST(c5 AS VARCHAR(20))      AS ruc,
            CASE
                WHEN UPPER(c6) IN ('1', 'TRUE')  THEN CAST(1 AS BIT)
                WHEN UPPER(c6) IN ('0', 'FALSE') THEN CAST(0 AS BIT)
                ELSE TRY_CAST(c6 AS BIT)
            END                          AS estado
        FROM P5
    ),
    DeduplicadoTxt AS (
        SELECT
            id_proveedor,
            nombre_proveedor,
            telefono,
            direccion,
            ruc,
            estado,
            ROW_NUMBER() OVER (PARTITION BY ruc ORDER BY id_proveedor ASC) AS rn_ruc
        FROM Convertido
        WHERE id_proveedor IS NOT NULL
          AND ruc IS NOT NULL
          AND LTRIM(RTRIM(ruc)) <> ''
          AND estado IS NOT NULL
    )
    SELECT
        id_proveedor,
        nombre_proveedor,
        telefono,
        direccion,
        ruc,
        estado
    INTO #OrigenParseado
    FROM DeduplicadoTxt
    WHERE rn_ruc = 1;

    BEGIN TRANSACTION;
        INSERT INTO dbo.Proveedor (
            id_proveedor,
            nombre_proveedor,
            telefono,
            direccion,
            ruc,
            estado
        )
        SELECT
            o.id_proveedor,
            o.nombre_proveedor,
            o.telefono,
            o.direccion,
            o.ruc,
            o.estado
        FROM #OrigenParseado o
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Proveedor p
            WHERE p.id_proveedor = o.id_proveedor
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.Proveedor p
            WHERE p.ruc = o.ruc
        );

    COMMIT TRANSACTION;

    DROP TABLE #OrigenParseado;
END
GO