-- luxury_multicharacter: Configuración Abierta para Administradores (Escrow Ignored)
Config = Config or {}

-- Número máximo de ranuras para personajes por jugador
Config.MaxCharacters = 4

-- Permitir a los jugadores eliminar sus propios personajes
Config.AllowDelete = true

-- Código PIN de confirmación para borrado de seguridad (o escribir DELETE)
Config.DeleteConfirmationWord = 'BORRAR'

-- Ubicación del escenario de selección y vista previa 3D de personajes (LSIA Terminal)
Config.PreviewLocation = {
    pedCoords = vector4(-1045.24, -2750.14, 21.36, 330.0),
    camCoords = vector3(-1043.14, -2747.00, 21.80),
    camRot = vector3(-5.0, 0.0, 150.0),
    camFov = 38.0
}

-- Ubicaciones de aparición para nuevos personajes
Config.DefaultSpawns = {
    { label = 'Aeropuerto Internacional (LSIA)', coords = vector4(-1037.69, -2737.81, 20.17, 330.0) },
    { label = 'Terminal de Autobuses de Legion Square', coords = vector4(432.96, -646.68, 28.73, 90.0) },
    { label = 'Estación de Trenes de Sandy Shores', coords = vector4(1877.21, 3705.48, 33.22, 210.0) }
}
