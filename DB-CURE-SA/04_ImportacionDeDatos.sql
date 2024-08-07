/*CARGA DE DATOS/IMPORTACION DE CSV Y JSON*/

/*VERIFICAR RUTAS ANTES DE EJECUTAR*/

USE [Com5600G18]
GO



EXEC Proceso.Cargar_Datos_Medico_CSV @Ruta_Archivo = 'C:\Clinica_Cure_SA\Dataset\Medicos.csv';
GO


EXEC Proceso.Cargar_Datos_Sedes_CSV @Ruta_Archivo = 'C:\Clinica_Cure_SA\Dataset\Sedes.csv';
GO


EXEC Proceso.Cargar_Datos_Pacientes_CSV @Ruta_Archivo = 'C:\Clinica_Cure_SA\Dataset\Pacientes.csv';
GO


EXEC Proceso.Cargar_Datos_Prestador_CSV @Ruta_Archivo = 'C:\Clinica_Cure_SA\Dataset\Prestador.csv';
GO


EXEC Proceso.Cargar_Datos_Centro_Autorizaciones_JSON @Ruta_Archivo = 'C:\Clinica_Cure_SA\Dataset\Centro_Autorizaciones.Estudios clinicos.json';
GO



/*CARGA DE TABLAS VACIAS*/
EXEC Proceso.Cargar_Estado_Turno;
GO

EXEC Proceso.Cargar_Tipo_Turno;
GO

EXEC Proceso.Cargar_Dias_X_Sede;
GO

EXEC Proceso.Generar_Cobertura;
GO

EXEC Proceso.Cargar_Reserva_Turno_Medico '2024-06-15', '10:00:00', 45, 1, 1;
GO
EXEC Proceso.Cargar_Reserva_Turno_Medico '2024-06-20', '14:30:00', 60, 7, 2;
GO
