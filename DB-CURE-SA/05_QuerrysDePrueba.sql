/*CONSULTAS VARIADAS*/

USE Com5600G18
GO

SELECT DATABASEPROPERTYEX('Com5600G18', 'Collation') AS Collation;
/*debe ser Modern_Spanish_100_CS_AS_SC_UTF8*/

select *
From Clinica.Medico
go

Select *
from Clinica.Especialidad
go

select *
from clinica.Dias_X_Sede

Select *
from Clinica.Domicilio
go

Select *
from Clinica.Sede_Atencion
go

Select *
from Clinica.Paciente
go

Select *
from Clinica.Prestador
go

DBCC CHECKIDENT ([Clinica.Sede_Atencion], RESEED, 0)

DELETE FROM Clinica.Prestador;
go

DELETE FROM Clinica.Sede_Atencion;
go

select * from Clinica.Reserva_Turno_Medico


Select *
from Clinica.Estudio
go

DBCC CHECKIDENT ([Clinica.Estudio], RESEED, 0)


Drop table Clinica.Estudio
go

------------------
DROP PROCEDURE Proceso.Cargar_Datos_Pacientes_CSV
GO
----------------
-----------------------------------------------------------------------
--json carga de estudios manual 'C:\Clinica_Cure_SA\Dataset\Centro_Autorizaciones.Estudios clinicos.json'
-- Crear la tabla temporal para cargar los datos del JSON
  -- Tabla temporal para cargar los datos del JSON
    CREATE TABLE #Temp_Estudio (
        Area NVARCHAR(40),
        Estudio NVARCHAR(100),
        Prestador NVARCHAR(50),
        Plan_Prestador NVARCHAR(50),
        Porcentaje_Cobertura DECIMAL(10, 2),
        Costo DECIMAL(10, 2),
        Requiere_Autorizacion BIT,
        Fecha DATE DEFAULT GETDATE()
    );

-- Cargar datos JSON a la tabla temporal
INSERT INTO #Temp_Estudio (Area, Estudio, Prestador, Plan_Prestador, Porcentaje_Cobertura, Costo, Requiere_Autorizacion, Fecha)
SELECT
   JSON_VALUE(subjson.value, '$.Area') AS Area,
    JSON_VALUE(subjson.value, '$.Estudio') AS Estudio,
    JSON_VALUE(subjson.value, '$.Prestador') AS Prestador,
    JSON_VALUE(subjson.value, '$."Plan"') AS Plan_Prestador,
    CAST(JSON_VALUE(subjson.value, '$."Porcentaje Cobertura"') AS DECIMAL(10, 2)) AS Porcentaje_Cobertura,
    CAST(JSON_VALUE(subjson.value, '$.Costo') AS DECIMAL(10, 2)) AS Costo,
    CAST(JSON_VALUE(subjson.value, '$."Requiere autorizacion"') AS BIT) AS Requiere_Autorizacion,
    GETDATE() AS Fecha
FROM
    OPENROWSET (
        BULK 'C:\Clinica_Cure_SA\Dataset\Centro_Autorizaciones.Estudios clinicos.json',
        SINGLE_CLOB,
        CODEPAGE = '65001' 
    ) AS bulkData
CROSS APPLY OPENJSON(bulkData.BulkColumn) AS subjson
WHERE JSON_VALUE(subjson.value, '$.Area') IS NOT NULL
;
go

 -- Corregir caracteres
UPDATE #Temp_Estudio
    SET 
        Area = Funcion.CorregirCaracteres(Area),
        Estudio = Funcion.CorregirCaracteres(Estudio),
        Prestador = Funcion.CorregirCaracteres(Prestador),
        Plan_Prestador = Funcion.CorregirCaracteres(Plan_Prestador)


		 MERGE INTO Clinica.Estudio AS Target
    USING (
        SELECT
            -- Columna única para identificar los registros duplicados
            ROW_NUMBER() OVER (PARTITION BY Area, Estudio, Prestador, Plan_Prestador ORDER BY Fecha) AS RowNum,
            GETDATE() AS Fecha,
            Funcion.CorregirCaracteres(Area) AS Area,
            Funcion.CorregirCaracteres(Estudio) AS Nombre_Estudio,
            Funcion.CorregirCaracteres(Prestador) AS Prestador,
            Funcion.CorregirCaracteres(Plan_Prestador) AS Plan_Prestador,
            Porcentaje_Cobertura,
            CASE WHEN Requiere_Autorizacion = 1 THEN 0 ELSE 1 END AS Autorizado,
            0.0 AS Importe_Facturar, -- Valor predeterminado
            NULL AS Documento_Resultado, -- Valor predeterminado
            NULL AS Imagen_Resultado-- Valor predeterminado
        FROM #Temp_Estudio
    ) AS Source ON Target.Area = Source.Area AND Target.Nombre_Estudio = Source.Nombre_Estudio AND Target.Prestador = Source.Prestador AND Target.Plan_Prestador = Source.Plan_Prestador
    WHEN NOT MATCHED THEN
        INSERT (Fecha, Area, Nombre_Estudio, Prestador, Plan_Prestador, Porcentaje_Cobertura, Autorizado, Importe_Facturar, Documento_Resultado, Imagen_Resultado)
        VALUES (Source.Fecha, Source.Area, Source.Nombre_Estudio, Source.Prestador, Source.Plan_Prestador, Source.Porcentaje_Cobertura, Source.Autorizado, Source.Importe_Facturar, Source.Documento_Resultado, Source.Imagen_Resultado)
    WHEN MATCHED THEN
        UPDATE SET Target.Fecha = Source.Fecha; -- Actualizar la fecha si ya existe el registro pero es un duplicado

-- ver contenido de la tabla temporal
SELECT * FROM #Temp_Estudio;
go


delete from #Temp_Estudio


select * from Clinica.Estudio


delete from Clinica.Estudio

drop table #Temp_Estudio;
go


---------------------------------


SELECT TABLE_NAME, COLUMN_NAME, COLLATION_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Clinica' AND TABLE_NAME = 'Sede_Atencion';
go


SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'Clinica' 
AND TABLE_NAME = 'Sede_Atencion' OR TABLE_NAME = 'Paciente';
go


-- Eliminar la tabla Clinica.Reserva_Turno_Medico
DROP TABLE IF EXISTS Clinica.Reserva_Turno_Medico;
GO

-- Eliminar la tabla Clinica.Dias_X_Sede
DROP TABLE IF EXISTS Clinica.Dias_X_Sede;
GO

-- Eliminar la tabla Clinica.Medico
DROP TABLE IF EXISTS Clinica.Medico;
GO

-- Eliminar la tabla Clinica.Especialidad
DROP TABLE IF EXISTS Clinica.Especialidad;
GO

-- Eliminar la tabla Clinica.Sede_Atencion
DROP TABLE IF EXISTS Clinica.Sede_Atencion;
GO

-- Eliminar la tabla Clinica.Tipo_Turno
DROP TABLE IF EXISTS Clinica.Tipo_Turno;
GO

-- Eliminar la tabla Clinica.Estado_Turno
DROP TABLE IF EXISTS Clinica.Estado_Turno;
GO

-- Eliminar la tabla Clinica.Estudio
DROP TABLE IF EXISTS Clinica.Estudio;
GO

-- Eliminar la tabla Clinica.Cobertura
DROP TABLE IF EXISTS Clinica.Cobertura;
GO

-- Eliminar la tabla Clinica.Prestador
DROP TABLE IF EXISTS Clinica.Prestador;
GO

-- Eliminar la tabla Clinica.Usuario
DROP TABLE IF EXISTS Clinica.Usuario;
GO

-- Eliminar la tabla Clinica.Domicilio
DROP TABLE IF EXISTS Clinica.Domicilio;
GO

-- Eliminar la tabla Clinica.Paciente
DROP TABLE IF EXISTS Clinica.Paciente;
GO
