USE [Com5600G18]
GO


/*----------------------Creacion de XML---------------------------*/
CREATE OR ALTER PROCEDURE Proceso.CargarXML (@Nombre_Prestador VARCHAR(40), @Fecha1 DATE, @Fecha2 DATE)
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #Temp_ID_Prestador(
		ID_Prestador INT
	);

	INSERT INTO #Temp_ID_Prestador
	SELECT ID_Prestador FROM Clinica.Prestador WHERE Nombre_Prestador = @Nombre_Prestador;

	CREATE TABLE #Temp_XML (
		ID_Historia_Clinica INT,
		ID_Medico INT,
		ID_Especialidad INT,
		Nombre VARCHAR(50),
		Apellido VARCHAR(50),
		Nro_Documento VARCHAR(20),
		Nombre_Medico VARCHAR(100),
		Nro_Matricula VARCHAR(50),
		Nombre_Especialidad VARCHAR(100),
		Fecha DATE,
		Hora TIME
	);

	--Obtengo los registros validos dadas los parametros de entrada del SP
	INSERT INTO #Temp_XML (ID_Historia_Clinica, ID_Medico, ID_Especialidad, Hora)
	SELECT ID_Paciente, Id_Medico, ID_Especialidad, Hora
	FROM Clinica.Reserva_Turno_Medico
	WHERE ID_Prestador IN (Select ID_Prestador FROM #Temp_ID_Prestador) AND Fecha BETWEEN @Fecha1 AND @Fecha2;

	--Usando el Id correspondiente obtengo de otras tablas los registros
	UPDATE #Temp_XML
	SET Nombre = p.Nombre,
	Apellido = p.Apellido,
	Nro_Documento = p.Nro_Documento
	FROM #Temp_XML t
	INNER JOIN Clinica.Paciente p ON t.ID_Historia_Clinica = p.ID_Historia_Clinica;
	

	UPDATE #Temp_XML
	SET Nombre_Medico = m.Nombre_Medico,
	Nro_Matricula = m.Nro_Matricula
	FROM #Temp_XML t
	INNER JOIN Clinica.Medico m ON t.ID_Medico = m.ID_Medico;


	UPDATE #Temp_XML
	SET Nombre_Especialidad = e.Nombre_Especialidad
	FROM #Temp_XML t
	INNER JOIN Clinica.Especialidad e ON t.ID_Especialidad = e.ID_Especialidad;


	--Muestro el resultado en formato XML
	SELECT Nombre, Apellido, Nro_Documento, Nombre_Medico, Nro_Matricula, Nombre_Especialidad, Fecha, Hora
	FROM #Temp_XML
	FOR XML AUTO, ROOT('Root'), ELEMENTS;

	DROP TABLE #Temp_ID_Prestador;
	DROP TABLE #Temp_XML;


END;
GO
