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
    SET @ret = REPLACE(@texto, 'á', '�');
    SET @ret = REPLACE(@ret, 'é', '�');
	SET @ret = REPLACE(@ret, 'ú', '�');
    SET @ret = REPLACE(@ret, 'ñ', '�');
	SET @ret = REPLACE(@ret, 'ó', '�');
    SET @ret = REPLACE(@ret, 'í', '�');
    
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