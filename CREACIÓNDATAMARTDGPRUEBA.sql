create database datamartDGprueba
go

use datamartDGprueba
go
create table dim_cliente
(
    id_cliente int primary key identity,
    pk_cliente char(10),
    nombre varchar(150),
    id_distrito varchar(10),
    id_zona varchar(10)
)
go

SELECT * FROM dim_cliente
DELETE FROM dim_cliente
TRUNCATE TABLE dim_cliente


create table dim_producto
(
   id_producto int primary key identity,
   pk_producto varchar(10),
   nombre_producto varchar(200),
   categoria varchar(100)
)
go

SELECT * FROM dim_producto

create table dim_vendedor
(
    id_vendedor int primary key identity,
    pk_vendedor varchar(10),
    nombre varchar(100),
    canal varchar(30)
)
go

create table dim_tiempo
(
    fecha date primary key,
    anio smallint,
    mes smallint,
    diaMes smallint,
    diaSemana varchar(15),
    trimestre smallint
)
go

SELECT * FROM dim_tiempo
DELETE FROM dim_tiempo

CREATE TABLE dim_ubicacion
(
    id_ubicacion INT PRIMARY KEY IDENTITY,
    pk_zona VARCHAR(10),
    distrito VARCHAR(100),
    zona VARCHAR(100),
    mercado VARCHAR(150)
)
go

create table fact_ventas
(
    id_cliente INT,
    id_producto INT,
    id_vendedor INT,
    fecha DATE,
    id_ubicacion INT,

    cantidad INT,
    precio_unitario decimal(10,2),
    precio_mayor decimal (10,2),
    total DECIMAL(10,2),

    FOREIGN KEY (id_cliente) REFERENCES dim_cliente(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES dim_producto(id_producto),
    FOREIGN KEY (id_vendedor) REFERENCES dim_vendedor(id_vendedor),
    FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha),
    FOREIGN KEY (id_ubicacion) REFERENCES dim_ubicacion(id_ubicacion)
)