/*PROCESOS ALMACENADOS*/
/* Vamos a usar para cargar los .csv:
FIELDTERMINATOR = '';'',  -- Delimitador para el campo
ROWTERMINATOR = ''\n'',   -- Delimitador de filas
FIRSTROW = 2,             -- Por si la primera fila contiene encabezados, los salteamos
CODEPAGE = ''65001'',     -- Especifica que el archivo CSV está en UTF-8(aunque algunos estan en UTF-8 BOM)
DATAFILETYPE = ''char''   -- Especifica que los datos son de tipo char (esto maneja el BOM)*/

USE [Com5600G18]
GO

/*---------------------------------------------------*/
/*------------------Desde csv Medicos--------------------------*/

CREATE OR ALTER PROCEDURE Proceso.Cargar_Datos_Medico_CSV @Ruta_Archivo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Temp_Medico (
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Especialidad VARCHAR(100),
        Numero_Colegiado VARCHAR(50)
    );

	 BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = N'
    BULK INSERT #Temp_Medico
    FROM ''' + @Ruta_Archivo + '''
    WITH (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''\n'',
        FIRSTROW = 2,
        CODEPAGE = ''65001'',
        DATAFILETYPE = ''char''
    );';

    EXEC sp_executesql @SQL;

	END TRY
    BEGIN CATCH
        -- Manejo del error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Informar al usuario del error
        RAISERROR ('Error durante la carga BULK INSERT: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);

        RETURN;
    END CATCH


	INSERT INTO Clinica.Especialidad (Nombre_Especialidad)
	SELECT DISTINCT t.Especialidad
	FROM #Temp_Medico t
	WHERE NOT EXISTS (
		SELECT 1
		FROM Clinica.Especialidad e
		WHERE e.Nombre_Especialidad = t.Especialidad
	);

	INSERT INTO Clinica.Medico (Nombre_Medico, Apellido_Medico, Nro_Matricula, ID_Especialidad)
	SELECT t.Nombre, t.Apellido, t.Numero_Colegiado, e.ID_Especialidad
	FROM #Temp_Medico t
	JOIN Clinica.Especialidad e ON t.Especialidad = e.Nombre_Especialidad
	WHERE NOT EXISTS (
		SELECT 1
		FROM Clinica.Medico m
		WHERE m.Nro_Matricula = t.Numero_Colegiado
	);


    DROP TABLE #Temp_Medico;

END;
GO


/*------------------Desde csv Sedes--------------------------*/
CREATE OR ALTER PROCEDURE Proceso.Cargar_Datos_Sedes_CSV @Ruta_Archivo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Temp_Sede(
        Nombre_Sede VARCHAR(100),
        Direccion_Sede VARCHAR(255),
        Localidad_Sede VARCHAR(100),
        Provincia_Sede VARCHAR(100)
    );

	BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = N'
    BULK INSERT #Temp_Sede
    FROM ''' + @Ruta_Archivo + '''
    WITH (
        FIELDTERMINATOR = '';'',  
        ROWTERMINATOR = ''\n'',   
        FIRSTROW = 2,             
        CODEPAGE = ''65001'',     
        DATAFILETYPE = ''char''   
    );';

    EXEC sp_executesql @SQL;
	END TRY
    BEGIN CATCH
        -- Manejo del error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Informar al usuario del error
        RAISERROR ('Error durante la carga BULK INSERT: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);

        RETURN;
    END CATCH


    -- Limpia los espacios en blanco adicionales
    INSERT INTO Clinica.Sede_Atencion (Nombre_Sede, Direccion_Sede, Localidad_Sede, Provincia_Sede)
    SELECT 
        LTRIM(RTRIM(ts.Nombre_Sede)), 
        LTRIM(RTRIM(ts.Direccion_Sede)), 
        LTRIM(RTRIM(ts.Localidad_Sede)), 
        LTRIM(RTRIM(ts.Provincia_Sede))
    FROM #Temp_Sede ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM Clinica.Sede_Atencion sa
        WHERE sa.Nombre_Sede = LTRIM(RTRIM(ts.Nombre_Sede))
    );

    DROP TABLE #Temp_Sede;
END;
GO


/*------------------Desde csv Pacientes--------------------------*/
/*------------------Para Apellido materno, pone null en ese campo*/

CREATE OR ALTER PROCEDURE Proceso.Cargar_Datos_Pacientes_CSV
    @Ruta_Archivo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Crear la tabla temporal
        CREATE TABLE #TempPacientes (
            Nombre NVARCHAR(100),
            Apellido NVARCHAR(100),
            Fecha_Nacimiento NVARCHAR(10),  
            Tipo_Documento NVARCHAR(50),
            Nro_Documento NVARCHAR(20),
            Femenino NVARCHAR(10),
            Genero NVARCHAR(10),
            Telefono_Fijo NVARCHAR(20),
            Nacionalidad NVARCHAR(50),
            Mail NVARCHAR(100),
            CalleYNumero NVARCHAR(150),  
            Localidad NVARCHAR(100),
            Provincia NVARCHAR(100)
        );

        -- Cargar datos desde el CSV a la tabla temporal
        DECLARE @SQL NVARCHAR(MAX) = N'
        BULK INSERT #TempPacientes
        FROM ''' + @Ruta_Archivo + '''
        WITH (
            FIELDTERMINATOR = '';'',  
            ROWTERMINATOR = ''\n'',   
            FIRSTROW = 2,             
            CODEPAGE = ''65001'',     
            DATAFILETYPE = ''char''   
        );';

        EXEC sp_executesql @SQL;

        -- Insertar datos en Clinica.Paciente si no existen duplicados
        INSERT INTO Clinica.Paciente (
            Nombre,
            Apellido,
            Fecha_Nacimiento,
            Tipo_Documento,
            Nro_Documento,
            Sexo_Biologico,
            Genero,
            Nacionalidad,
            Mail,
            Telefono_Fijo,
            Fecha_Actualizacion,
            Usuario_Actualizacion
        )
        SELECT
            Nombre,
            Apellido,
            TRY_CONVERT(DATE, Fecha_Nacimiento, 103), -- formato DD/MM/YYYY, por eso el 103
            Tipo_Documento,
            Nro_Documento,
            CASE
                WHEN Femenino = 'S' THEN 'Femenino'
                ELSE 'Masculino'
            END AS Sexo_Biologico,
            Genero,
            UPPER(LEFT(Nacionalidad, 1)) + LOWER(SUBSTRING(Nacionalidad, 2, LEN(Nacionalidad) - 1)) AS Nacionalidad,
            Mail,
            Telefono_Fijo,
            GETDATE() AS Fecha_Actualizacion,
            SUSER_SNAME() AS Usuario_Actualizacion -- Reemplaza por el usuario adecuado
        FROM
            #TempPacientes tp
        WHERE
            Nombre IS NOT NULL
--
            AND NOT EXISTS (
                SELECT 1 
                FROM Clinica.Paciente p 
                WHERE p.Nro_Documento = tp.Nro_Documento
            );

        -- Usamos un CTE para facilitar la separación de CalleYNumero
        WITH SeparatedCalleNumero AS (
            SELECT
                Nombre,
                Apellido,
                CalleYNumero,
                Localidad,
                Provincia,
                Nro_Documento,
                -- Intentamos encontrar el número al final de la cadena
                CASE
                    WHEN PATINDEX('%[0-9]%', CalleYNumero) > 0 THEN
                        RTRIM(LEFT(CalleYNumero, PATINDEX('%[0-9]%', CalleYNumero + ' ') - 1))
                    ELSE CalleYNumero
                END AS Calle,
                -- Buscamos el último conjunto de dígitos que consideramos el número
                CASE
                    WHEN PATINDEX('%[0-9]%', CalleYNumero) > 0 THEN
                        RIGHT(CalleYNumero, LEN(CalleYNumero) - PATINDEX('%[0-9]%', CalleYNumero) + 1)
                    ELSE '0'
                END AS Numero
            FROM #TempPacientes
        )
        INSERT INTO Clinica.Domicilio (
            Calle,
            Numero,
            Piso,
            Departamento,
            Codigo_postal,
            Pais,
            Provincia,
            Localidad,
            ID_Historia_Clinica
        )
        SELECT
            Calle,
            CASE
                WHEN ISNUMERIC(Numero) = 1 THEN CAST(Numero AS INT)
                ELSE 0 -- seteamos a 0 si no hay nada
            END AS Numero,
            NULL AS Piso, 
            NULL AS Departamento, 
            '0000' AS Codigo_postal, 
            'Argentina' AS Pais, 
            Provincia,
            Localidad,
            p.ID_Historia_Clinica
        FROM
            SeparatedCalleNumero sc
        JOIN
            Clinica.Paciente p ON sc.Nro_Documento = p.Nro_Documento
        WHERE
            Calle IS NOT NULL;

        -- Limpieza de la tabla temporal
        DROP TABLE #TempPacientes;
    END TRY
    BEGIN CATCH
        -- Manejar el error
        PRINT 'Ha ocurrido un error durante la inserción: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO


/*---------------------------------------------------*/
/*------------------Desde csv Prestador--------------------------*/

CREATE OR ALTER PROCEDURE Proceso.Cargar_Datos_Prestador_CSV @Ruta_Archivo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Temp_Prestador (
        Nombre_Prestador VARCHAR(40),
        Plan_Prestador VARCHAR(40)
    );

	BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX) = N'
    BULK INSERT #Temp_Prestador
    FROM ''' + @Ruta_Archivo + '''
    WITH (
        FIELDTERMINATOR = '';'',  
        ROWTERMINATOR = ''\n'',   
        FIRSTROW = 2,             
        CODEPAGE = ''65001'',     
        DATAFILETYPE = ''char''   
    );';

    EXEC sp_executesql @SQL;
	END TRY
    BEGIN CATCH
        -- Manejo del error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Informar al usuario del error
        RAISERROR ('Error durante la carga BULK INSERT: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);

        RETURN;
    END CATCH


	-- Quita los ";;" al final de los campos antes de insertar(Analizando el .csv se ve que terminan con doble ;)
	UPDATE #Temp_Prestador
	SET Nombre_Prestador = RTRIM(REPLACE(Nombre_Prestador, ';;', '')),
	Plan_Prestador = RTRIM(REPLACE(Plan_Prestador, ';;', ''));

    INSERT INTO Clinica.Prestador (Nombre_Prestador, Plan_Prestador)
    SELECT 
    t.Nombre_Prestador,
	t.Plan_Prestador
    FROM #Temp_Prestador t
    WHERE NOT EXISTS (
        SELECT 1
        FROM Clinica.Prestador p
        WHERE p.Nombre_Prestador = t.Nombre_Prestador
          AND p.Plan_Prestador = t.Plan_Prestador
    );

    DROP TABLE #Temp_Prestador;
END;
GO


/*---------------------------------------------------*/
/*------------------Desde json Estudios--------------------------*/

CREATE OR ALTER PROCEDURE Proceso.Cargar_Datos_Centro_Autorizaciones_JSON @Ruta_Archivo NVARCHAR(255)
AS
BEGIN
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
	BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        INSERT INTO #Temp_Estudio (Area, Estudio, Prestador, Plan_Prestador, Porcentaje_Cobertura, Costo, Requiere_Autorizacion, Fecha)
        SELECT
            JSON_VALUE(subjson.value, ''$.Area'') AS Area,
            JSON_VALUE(subjson.value, ''$.Estudio'') AS Estudio,
            JSON_VALUE(subjson.value, ''$.Prestador'') AS Prestador,
            JSON_VALUE(subjson.value, ''$."Plan"'') AS Plan_Prestador,
            CAST(JSON_VALUE(subjson.value, ''$."Porcentaje Cobertura"'') AS DECIMAL(10, 2)) AS Porcentaje_Cobertura,
            CAST(JSON_VALUE(subjson.value, ''$.Costo'') AS DECIMAL(10, 2)) AS Costo,
            CAST(JSON_VALUE(subjson.value, ''$."Requiere autorizacion"'') AS BIT) AS Requiere_Autorizacion,
            GETDATE() AS Fecha
        FROM
            OPENROWSET (
                BULK ''' + @Ruta_Archivo + ''',
                SINGLE_CLOB,
                CODEPAGE = ''65001''  
            ) AS bulkData
        CROSS APPLY OPENJSON(bulkData.BulkColumn) AS subjson
		WHERE JSON_VALUE(subjson.value, ''$.Area'') IS NOT NULL;
    ';
    EXEC sp_executesql @SQL;
	END TRY
    BEGIN CATCH
        -- Manejo del error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Informar al usuario del error
        RAISERROR ('Error durante la carga BULK INSERT: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);

        RETURN;
    END CATCH


    -- Insertar datos en la tabla Clinica.Estudio y manejar duplicados
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
END;
GO

/*---------------------------------------------------*/
/*------------------Tablas con Valores Aleatorios--------------------------*/

--Estado Turno
CREATE OR ALTER PROCEDURE Proceso.Cargar_Estado_Turno
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Clinica.Estado_Turno)
    BEGIN
        INSERT INTO Clinica.Estado_Turno (Nombre_Estado)
        VALUES
            ('Atendido'),
            ('Ausente'),
            ('Cancelado'),
            ('Disponible'),
            ('Reservado');
    END
END;
GO

--Tipo Turno
CREATE OR ALTER PROCEDURE Proceso.Cargar_Tipo_Turno
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Clinica.Tipo_Turno)
    BEGIN
        INSERT INTO Clinica.Tipo_Turno (Nombre_Tipo_Turno)
        VALUES
            ('Presencial'),
            ('Virtual');
    END
END;
GO



--Dias X Sede

CREATE OR ALTER PROCEDURE Proceso.Cargar_Dias_X_Sede
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Count INT = 0;
    DECLARE @Max INT = 100;

    WHILE @Count < @Max
    BEGIN

        DECLARE @ID_Sede INT = (SELECT TOP 1 ID_Sede FROM Clinica.Sede_Atencion ORDER BY NEWID());
        DECLARE @ID_Medico INT = (SELECT TOP 1 ID_Medico FROM Clinica.Medico ORDER BY NEWID());
        DECLARE @Dia VARCHAR(10) = (		SELECT TOP 1 Dia
											FROM (VALUES ('Lunes'), ('Martes'), ('Miércoles'), ('Jueves'), ('Viernes'), ('Sábado'), ('Domingo')) AS D(Dia)
											ORDER BY NEWID()
        );
        IF NOT EXISTS (
            SELECT 1
            FROM Clinica.Dias_X_Sede
            WHERE ID_Sede = @ID_Sede
              AND ID_Medico = @ID_Medico
              AND Dia = @Dia
        )
        BEGIN
            INSERT INTO Clinica.Dias_X_Sede (ID_Sede, ID_Medico, Dia, Hora_Inicio)
            VALUES (@ID_Sede, @ID_Medico, @Dia, CAST(DATEADD(MINUTE, (ABS(CHECKSUM(NEWID())) % (24*60 / 15)) * 15, '00:00:00') AS TIME));
        END;
        SET @Count = @Count + 1;
    END;

END;
GO



--Cobertura

CREATE OR ALTER PROCEDURE Proceso.Generar_Cobertura
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Count INT = 0;
    DECLARE @Max INT = 100;

    WHILE @Count < @Max
    BEGIN
        DECLARE @Nro_Socio INT;
        DECLARE @Prestador INT;

        SELECT TOP 1 @Nro_Socio = ID_Historia_Clinica
        FROM Clinica.Paciente
        ORDER BY NEWID();

        SELECT TOP 1 @Prestador = ID_Prestador
        FROM Clinica.Prestador
        ORDER BY NEWID();

        INSERT INTO Clinica.Cobertura (Nro_Socio, Prestador, Fecha_Registro)
        VALUES (@Nro_Socio, @Prestador, GETDATE());

        SET @Count = @Count + 1;
    END;
END;
GO





--Reserva_Turno_Medico

CREATE OR ALTER PROCEDURE Proceso.Cargar_Reserva_Turno_Medico @Fecha DATE, @Hora TIME, @ID_Paciente INT, @ID_Medico INT, @ID_Tipo_Turno INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ID_Especialidad INT;
    DECLARE @ID_Direccion_atencion INT;
    DECLARE @ID_Estado_Turno INT;
    DECLARE @ID_Prestador INT;

	--Se obtienen los valores de FK
    SELECT @ID_Especialidad = ID_Especialidad 
    FROM Clinica.Medico 
    WHERE ID_Medico = @ID_Medico;

    SELECT TOP 1 @ID_Direccion_atencion = ID_Sede 
    FROM Clinica.Dias_X_Sede
    WHERE ID_Medico = @ID_Medico 
    ORDER BY NEWID();

    SELECT @ID_Estado_Turno = ID_Estado 
    FROM Clinica.Estado_Turno 
    WHERE Nombre_Estado = 'Reservado';

	SELECT @ID_Prestador = c.Prestador
	FROM Clinica.Cobertura c
	INNER JOIN Clinica.Paciente p ON c.Nro_Socio = p.ID_Historia_Clinica
	WHERE p.ID_Historia_Clinica = @ID_Paciente;


	--Se insertan en la tabla no duplicados 
    INSERT INTO Clinica.Reserva_Turno_Medico (Fecha, Hora, ID_Paciente, ID_Medico, ID_Especialidad, ID_Direccion_atencion, ID_Estado_Turno, ID_Tipo_Turno, ID_Prestador)
    SELECT @Fecha, @Hora, @ID_Paciente, @ID_Medico, @ID_Especialidad, @ID_Direccion_atencion, @ID_Estado_Turno, @ID_Tipo_Turno, @ID_Prestador
    WHERE NOT EXISTS (
        SELECT 1
        FROM Clinica.Reserva_Turno_Medico
        WHERE Fecha = @Fecha
          AND Hora = @Hora
          AND ID_Paciente = @ID_Paciente
          AND ID_Medico = @ID_Medico
    )AND EXISTS(
		SELECT 1
		FROM Clinica.Paciente
		WHERE ID_Historia_Clinica = @ID_Paciente 
	)AND EXISTS(
		SELECT 1
		FROM Clinica.Medico
		WHERE ID_Medico = @ID_Medico
	)


END;
GO




