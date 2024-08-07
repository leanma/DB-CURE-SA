USE [Com5600G18]
GO

/*---------------------------------Creacion de logins y usuarios----------------------------------*/

CREATE LOGIN [ADMINISTRADOR] WITH PASSWORD = N'admin1234' , DEFAULT_DATABASE = [Com5600G18];
GO
CREATE LOGIN [PROGRAMADOR] WITH PASSWORD = N'progra1234' , DEFAULT_DATABASE = [Com5600G18];
GO

CREATE USER [Administrador_Usuario] FOR LOGIN [ADMINISTRADOR];
GO
CREATE USER [Programador_Usuario] FOR LOGIN [PROGRAMADOR];
GO


/*---------------------------------Asignacion de permisos----------------------------------*/
GRANT CONTROL SERVER TO [Administrador_Usuario];--Control total al Administrador

GRANT CONTROL ON SCHEMA::Clinica TO [Programador_Usuario];--Control sobre los esquemas para el Programador
GRANT CONTROL ON SCHEMA::Funcion TO [Programador_Usuario];
GRANT CONTROL ON SCHEMA::Proceso TO [Programador_Usuario];
GO



/*---------------------------------Crear usuarios para los pacientes----------------------------------*/
CREATE OR ALTER PROCEDURE Proceso.CrearUsuario (@Usuario NVARCHAR(30), @Contrasenia NVARCHAR(30))
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL NVARCHAR(MAX)

    SET @SQL = 'CREATE LOGIN ' + QUOTENAME(@Usuario) + ' WITH PASSWORD = ''' + @Contrasenia + '''';
    EXEC sp_executesql @SQL;

    SET @SQL = 'CREATE USER ' + QUOTENAME(@Usuario) + ' FOR LOGIN ' + QUOTENAME(@Usuario);
    EXEC sp_executesql @SQL;

	SET @SQL = 'GRANT INSERT ON Clinica.Pacientes TO ' + QUOTENAME(@Usuario);--Control para insertar datos en la tabla pacientes
	EXEC sp_executesql @SQL;

END;
GO
