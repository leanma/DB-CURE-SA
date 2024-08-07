/*Para crear las tablas
El nombre de la tabla empezara con Mayusculas
Cada nombre de atributo tambien con Mayusculas, los espacios los tratamos con "_"

Campos como Documentos, fotos , los tratamos como si guardaramos el URL de donde esta almacenado
*/

USE [Com5600G18]
GO


/*CREACION DE TABLAS*/

CREATE TABLE Clinica.Paciente (
    ID_Historia_Clinica INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Apellido_Materno VARCHAR(50) NULL,
    Fecha_Nacimiento DATE NOT NULL CHECK (  Fecha_Nacimiento <= GETDATE() AND Fecha_Nacimiento >= DATEADD(YEAR, -120, GETDATE()) ),
    Tipo_Documento VARCHAR(20) NOT NULL CHECK (Tipo_Documento IN ('DNI', 'Pasaporte', 'Licencia')),
    Nro_Documento VARCHAR(20) NOT NULL UNIQUE,
    Sexo_Biologico VARCHAR(10) NOT NULL CHECK (Sexo_Biologico IN ('Femenino', 'Masculino')),
    Genero VARCHAR(50) NULL,
    Nacionalidad VARCHAR(50) NOT NULL,
    Foto_Perfil NVARCHAR(255) NULL,
    Mail NVARCHAR(100) NOT NULL,
    Telefono_Fijo VARCHAR(15) NULL,
    Telefono_Contacto_Alternativo VARCHAR(15) NULL,
    Telefono_Laboral VARCHAR(15) NULL,
    Fecha_Registro DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Actualizacion DATETIME NULL,
    Usuario_Actualizacion VARCHAR(50) NULL DEFAULT SUSER_SNAME()
);
GO


CREATE TABLE Clinica.Domicilio (
    ID_domicilio INT IDENTITY(1,1) PRIMARY KEY,
    Calle VARCHAR(100) NOT NULL,
    Numero INT NOT NULL,
    Piso INT NULL,
    Departamento VARCHAR(10) NULL,
    Codigo_postal VARCHAR(10) NOT NULL,
    Pais VARCHAR(70) NOT NULL,
    Provincia VARCHAR(70) NOT NULL,
    Localidad VARCHAR(70) NOT NULL,
    ID_Historia_Clinica INT NOT NULL,
    CONSTRAINT FK_Paciente_Domicilio FOREIGN KEY (ID_Historia_Clinica) REFERENCES Clinica.Paciente(ID_Historia_Clinica)
);
GO


CREATE TABLE Clinica.Usuario (
    ID_Usuario INT IDENTITY(1,1) PRIMARY KEY,
    ID_Historia_Clinica INT NOT NULL,
    Contraseña NVARCHAR(256) NOT NULL, /*Guardamos el hash de la contraseña y no el texto plano*/
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Paciente_Usuario FOREIGN KEY (ID_Historia_Clinica) REFERENCES Clinica.Paciente(ID_Historia_Clinica)
);
GO


CREATE TABLE Clinica.Prestador (
    ID_Prestador INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Prestador VARCHAR(40) NOT NULL,
    Plan_Prestador VARCHAR(40) NOT NULL,
);
GO


CREATE TABLE Clinica.Cobertura (
    ID_Cobertura INT IDENTITY(1,1) PRIMARY KEY,
    Nro_Socio INT NOT NULL,
    Imagen_Credencial NVARCHAR(255) NULL,
    Fecha_Registro DATETIME NOT NULL DEFAULT GETDATE(),
	Prestador INT NOT NULL,
    CONSTRAINT FK_Paciente_Cobertura FOREIGN KEY (Nro_Socio) REFERENCES Clinica.Paciente(ID_Historia_Clinica),
	CONSTRAINT FK_Prestador FOREIGN KEY (Prestador) REFERENCES Clinica.Prestador(ID_Prestador)
);
GO

CREATE TABLE Clinica.Estudio (
    ID_Estudio INT IDENTITY(1,1) PRIMARY KEY,
    ID_Historia_Clinica INT NULL,
    Fecha DATE NULL,
	Area VARCHAR(40)  NULL,
    Nombre_Estudio VARCHAR(100) NULL,
    Autorizado BIT  NULL,
	Porcentaje_Cobertura DECIMAL(10,2) NULL,
    Importe_Facturar DECIMAL(10, 2)  NULL DEFAULT 0.0, 
    Documento_Resultado NVARCHAR(255) NULL,
    Imagen_Resultado NVARCHAR(255) NULL,
	Prestador NVARCHAR(50) NULL,
	Plan_Prestador NVARCHAR(50) NULL,
);
GO

CREATE TABLE Clinica.Estado_Turno (
    ID_Estado INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Estado VARCHAR(20) NOT NULL CHECK (Nombre_Estado IN ('Atendido', 'Ausente', 'Cancelado','Disponible','Reservado'))
);
GO



CREATE TABLE Clinica.Tipo_Turno (
    ID_Tipo_Turno INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Tipo_Turno VARCHAR(20) NOT NULL CHECK (Nombre_Tipo_Turno IN ('Presencial', 'Virtual'))
);
GO


CREATE TABLE Clinica.Sede_Atencion (
    ID_Sede INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Sede VARCHAR(100) NOT NULL,
    Direccion_Sede VARCHAR(255) NOT NULL,
	Localidad_Sede VARCHAR(100) NOT NULL,
    Provincia_Sede VARCHAR(100) NOT NULL
);
GO


CREATE TABLE Clinica.Especialidad (
    ID_Especialidad INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Especialidad VARCHAR(100) NOT NULL
);
GO


CREATE TABLE Clinica.Medico (
    ID_Medico INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Medico VARCHAR(100) NOT NULL,
	Apellido_Medico VARCHAR(100) NOT NULL,
    ID_Especialidad INT NULL,
	Nro_Matricula VARCHAR(50) NOT NULL,
    CONSTRAINT FK_Especialidad_Medico FOREIGN KEY (ID_Especialidad) REFERENCES Clinica.Especialidad(ID_Especialidad)
);
GO


CREATE TABLE Clinica.Dias_X_Sede (
    ID_Sede INT NOT NULL,
    ID_Medico INT NOT NULL,
    Dia VARCHAR(10) NOT NULL CHECK (Dia IN ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo')),
    Hora_Inicio TIME NOT NULL,
	PRIMARY KEY (ID_Sede, ID_Medico, Dia),  
    CONSTRAINT FK_Sede_Atencion_Dias_X_Sede FOREIGN KEY (ID_Sede) REFERENCES Clinica.Sede_Atencion(ID_Sede),
    CONSTRAINT FK_Medico_Dias_X_Sede FOREIGN KEY (ID_Medico) REFERENCES Clinica.Medico(ID_Medico),
    CONSTRAINT CHK_Hora_Inicio_Dias_X_Sede CHECK (DATEPART(MINUTE, Hora_Inicio) % 15 = 0)/*calculo para que trate de guardar cada 15 minutos*/
);
GO



CREATE TABLE Clinica.Reserva_Turno_Medico (
    ID_Turno INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    Hora TIME NOT NULL,
    ID_Paciente INT NOT NULL,
    ID_Medico INT NOT NULL,
    ID_Especialidad INT NOT NULL,
    ID_Direccion_atencion INT NOT NULL,
    ID_Estado_Turno INT NOT NULL DEFAULT 'Disponible' CHECK (ID_Estado_Turno IN ('Disponible', 'Ausente', 'Atendido', 'Cancelado','Reservado')),
    ID_Tipo_Turno INT NOT NULL CHECK (ID_Tipo_Turno IN ('Presencial', 'Virtual')),
	ID_Prestador INT NOT NULL,
    CONSTRAINT FK_Paciente_Reserva_Turno FOREIGN KEY (ID_Paciente) REFERENCES Clinica.Paciente(ID_Historia_Clinica), 
    CONSTRAINT FK_Medico_Reserva_Turno FOREIGN KEY (ID_Medico) REFERENCES Clinica.Medico(ID_Medico),
    CONSTRAINT FK_Especialidad_Reserva_Turno FOREIGN KEY (ID_Especialidad) REFERENCES Clinica.Especialidad(ID_Especialidad),
    CONSTRAINT FK_Sede_Atencion_Reserva_Turno FOREIGN KEY (ID_Direccion_atencion) REFERENCES Clinica.Sede_Atencion(ID_Sede),
    CONSTRAINT FK_Estado_Turno_Reserva_Turno FOREIGN KEY (ID_Estado_Turno) REFERENCES Clinica.Estado_Turno(ID_Estado),
    CONSTRAINT FK_Tipo_Turno_Reserva_Turno FOREIGN KEY (ID_Tipo_Turno) REFERENCES Clinica.Tipo_Turno(ID_Tipo_Turno),
	CONSTRAINT FK_Prestador_Reserva_Turno FOREIGN KEY (ID_Prestador) REFERENCES Clinica.Prestador(ID_Prestador)
);
GO
