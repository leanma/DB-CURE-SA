USE [Com5600G18]
GO


CREATE OR ALTER FUNCTION Funcion.CorregirCaracteres(@texto NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
/*--
Se trabajan solo los caracteres comunes que por algun formato del json no se cargan correctamente
*/
BEGIN
    DECLARE @ret NVARCHAR(MAX);
    SET @ret = REPLACE(@texto, 'Ã¡', 'á');
    SET @ret = REPLACE(@ret, 'Ã©', 'é');
	SET @ret = REPLACE(@ret, 'Ãº', 'ú');
    SET @ret = REPLACE(@ret, 'Ã±', 'ñ');
	SET @ret = REPLACE(@ret, 'Ã³', 'ó');
    SET @ret = REPLACE(@ret, 'Ã­', 'í');
    
    RETURN @ret;
END;
GO

CREATE TRIGGER Clinica.Calcular_Otro_ID
ON Clinica.Estudio
AFTER INSERT
AS
BEGIN
    -- Actualizar el valor de ID_Historia_Clinica con el valor de ID_Estudio
    UPDATE Clinica.Estudio
    SET ID_Historia_Clinica = Clinica.Estudio.ID_Estudio
    FROM inserted
    WHERE Clinica.Estudio.ID_Estudio = inserted.ID_Estudio;
END;
GO