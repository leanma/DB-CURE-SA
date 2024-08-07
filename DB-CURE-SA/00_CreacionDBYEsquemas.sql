/*CREACION DE BASE DE DATOS*/
CREATE DATABASE Com5600G18
GO

/*CREACION DE ESQUEMA*/
USE Com5600G18
GO

CREATE SCHEMA Clinica
GO

CREATE SCHEMA Proceso
GO

CREATE SCHEMA Funcion
GO



/*VER INFORMACION DE LA BASE DE DATOS*/

/*COLLATE*/
SELECT name AS "Base de datos",collation_name AS "Collate"
FROM sys.databases
WHERE name = 'Com5600G18';
GO


/*ELIMINAR LA BASE DE DATOS*/
--DROP DATABASE Com5600G18
