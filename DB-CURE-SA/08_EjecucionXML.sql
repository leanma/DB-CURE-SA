/*EXPORTACIONES DE DATOS A XML*/


USE [Com5600G18]
GO


EXEC Proceso.CargarXML @Nombre_Prestador = 'Medicus', @Fecha1 = '2022-06-01', @Fecha2 = '2025-12-31';