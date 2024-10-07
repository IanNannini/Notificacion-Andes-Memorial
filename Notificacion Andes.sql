CREATE SCHEMA IF NOT EXISTS `andes` DEFAULT CHARACTER SET utf8 ;
USE `andes` ;

CREATE TABLE Usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    email VARCHAR(100),
    rol_usuario VARCHAR(50)
);
CREATE TABLE Estado (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estado VARCHAR(50)
);
CREATE TABLE ServicioFunerario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_servicio VARCHAR(100),
    descripcion TEXT,
    estado_id INT,
    asesor_id INT,
    operarioAsignado_id INT,
    documentacion VARCHAR(50),
    FOREIGN KEY (estado_id) REFERENCES Estado(id),
    FOREIGN KEY (asesor_id) REFERENCES Usuario(id),
    FOREIGN KEY (operarioAsignado_id) REFERENCES Usuario(id)

);
CREATE TABLE Notificacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mensaje TEXT,
    fecha DATETIME,
    mostrada BOOLEAN,
    idDestinatario INT,
    FOREIGN KEY (idDestinatario) REFERENCES Usuario(id)
);


DELIMITER $$

CREATE TRIGGER after_insert_servicio_funerario
AFTER INSERT ON ServicioFunerario
FOR EACH ROW
BEGIN
    -- Crear la notificaci n para cada usuario con el rol "Administrativo de Ventas"
    INSERT INTO Notificacion (mensaje, fecha, mostrada, idDestinatario)
    SELECT CONCAT('Se debe revisar la documentacion del servicio funerario con ID: ', NEW.id),
           NOW(), 
           FALSE, 
           Usuario.id
    FROM Usuario
    WHERE Usuario.rol_usuario = 'Administrativo de Ventas';
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER after_update_servicio_funerario
AFTER UPDATE ON ServicioFunerario
FOR EACH ROW
BEGIN
    -- Caso 1: Si el estado pasa de 1 a 2
    IF OLD.estado_id = 1 AND NEW.estado_id = 2 THEN
        -- Insertar una notificaci n para cada usuario con rol "Encargado de Mantenimiento"
        INSERT INTO Notificacion (mensaje, fecha, mostrada, idDestinatario)
        SELECT 
            CONCAT('Se debe asignar un operario al servicio funerario con ID: ', NEW.id),
            NOW(),
            FALSE,
            u.id
        FROM 
            Usuario u
        WHERE 
            u.rol_usuario = 'Encargado de Mantenimiento';
    END IF;

    -- Caso 2: Si el estado pasa de 2 a 3
    IF OLD.estado_id = 2 AND NEW.estado_id = 3 THEN
        -- Insertar una notificaci n para el operario asignado
        INSERT INTO Notificacion (mensaje, fecha, mostrada, idDestinatario)
        VALUES (
            CONCAT('Se debe realizar el servicio funerario con ID: ', NEW.id),
            NOW(),
            FALSE,
            NEW.operarioAsignado_id
        );
    END IF;

    -- Caso 3: Si el estado pasa de 3 a 4
    IF OLD.estado_id = 3 AND NEW.estado_id = 4 THEN
        -- Insertar una notificaci n para cada usuario con rol "Encargado de Mantenimiento"
        INSERT INTO Notificacion (mensaje, fecha, mostrada, idDestinatario)
        SELECT 
            CONCAT('El servicio funerario con ID: ', NEW.id, ' ha finalizado con  xito'),
            NOW(),
            FALSE,
            u.id
        FROM 
            Usuario u
        WHERE 
            u.rol_usuario = 'Encargado de Mantenimiento';
    END IF;

END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE mostrarNotificaciones(IN p_usuario_id INT)
BEGIN
    -- Mostrar todas las notificaciones asignadas al usuario que no se hayan mostrado (mostrada = FALSE)
    SELECT id, mensaje, fecha, mostrada
    FROM Notificacion
    WHERE idDestinatario = p_usuario_id
      AND mostrada = FALSE;

    -- Actualizar el campo 'mostrada' a TRUE para las notificaciones del usuario que no se hayan mostrado
    UPDATE Notificacion
    SET mostrada = TRUE
    WHERE idDestinatario = p_usuario_id
      AND mostrada = FALSE;
END$$

DELIMITER ;

-- Cargar distintos estados posibles
INSERT INTO Estado (id, estado) VALUES (1, 'documentacion cargada');
INSERT INTO Estado (id, estado) VALUES (2, 'documentacion revisada');
INSERT INTO Estado (id, estado) VALUES (3, 'operario asignado');
INSERT INTO Estado (id, estado) VALUES (4, 'finalizado');

-- Cargar usuarios
INSERT INTO Usuario (nombre, apellido, email, rol_usuario) 
VALUES 
('Walter', 'White', 'WalterWhite@hotmail.com', 'Operario'),
('Jesse', 'Pinkman', 'JessePinkman@hotmail.com', 'Cremador'),
('Gus', 'Fring', 'GusFring@hotmail.com', 'Encargado de Mantenimiento'),
('Saul', 'Goodman', 'SaulGoodman@hotmail.com', 'Asesor Comercial'),
('Hector', 'Salamanca', 'HectorSalamanca@hotmail.com', 'Administrativo de Ventas'),
('Skyler', 'White', 'SkylerWhite@hotmail.com', 'Cremador');

-- Ejemplo inserci n de nuevo servicio funerario
INSERT INTO ServicioFunerario (tipo_servicio, descripcion, estado_id, asesor_id, operarioAsignado_id, documentacion)
VALUES ('Entierro', 'Este es un servicio de entierro solicitado por Saul Goodman', 1, 4, NULL, 'Documentaci n del cliente');

-- Listar usuarios
SELECT * FROM Usuario;
-- Ejemplo de borrado de usuario
SET SQL_SAFE_UPDATES = 0;
DELETE FROM Usuario
WHERE nombre = 'Skyler' AND apellido = 'White';
SET SQL_SAFE_UPDATES = 1;
-- Listar usuarios de nuevo, para verificar el borrado
SELECT * FROM Usuario;
-- Mostrar notificaciones de Hector Salamanca 
CALL mostrarNotificaciones(5);
