-- luxury_core: Sugerencias y Autocompletado del Chat (Client-side Suggestions)

CreateThread(function()
    Wait(1000)

    -- Jugador y Economía
    TriggerEvent('chat:addSuggestion', '/dinero', 'Muestra tu saldo actual en efectivo y en el banco.')
    TriggerEvent('chat:addSuggestion', '/trabajo', 'Muestra tu trabajo, rango laboral y sueldo.')
    TriggerEvent('chat:addSuggestion', '/id', 'Muestra tu documento nacional de identidad (DNI/CitizenID).')

    -- Comandos de Jefes de Facción
    TriggerEvent('chat:addSuggestion', '/sociedad', 'Administra los fondos de tu facción o empresa.', {
        { name = 'acción', help = 'consultar | ingresar | retirar' },
        { name = 'cantidad', help = 'Monto de dinero a transferir (opcional para consultar)' }
    })
    TriggerEvent('chat:addSuggestion', '/contratar', 'Contrata a un ciudadano desempleado en tu empresa.', {
        { name = 'id', help = 'ID del jugador conectado' }
    })
    TriggerEvent('chat:addSuggestion', '/despedir', 'Despide a un empleado de tu empresa.', {
        { name = 'id', help = 'ID del jugador conectado' }
    })
    TriggerEvent('chat:addSuggestion', '/ascender', 'Asciende al siguiente rango a un empleado.', {
        { name = 'id', help = 'ID del empleado' }
    })
    TriggerEvent('chat:addSuggestion', '/degradar', 'Degrada al rango anterior a un empleado.', {
        { name = 'id', help = 'ID del empleado' }
    })

    -- Comandos de Administración
    TriggerEvent('chat:addSuggestion', '/setGroup', 'Asigna y persiste el rango administrativo de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'grupo', help = 'user | mod | admin' }
    })
    TriggerEvent('chat:addSuggestion', '/darDinero', 'Añade fondos a la cuenta de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'cuenta', help = 'cash | bank' },
        { name = 'cantidad', help = 'Monto a transferir' }
    })
    TriggerEvent('chat:addSuggestion', '/setJob', 'Asigna un trabajo y rango específico a un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'trabajo', help = 'Nombre técnico del trabajo (ej: police)' },
        { name = 'rango', help = 'Número del rango (ej: 0, 1, 2)' }
    })
    TriggerEvent('chat:addSuggestion', '/revive', 'Revive a un jugador inconsciente.', {
        { name = 'id', help = 'ID del jugador (opcional, por defecto tú mismo)' }
    })
    TriggerEvent('chat:addSuggestion', '/noclip', 'Activa o desactiva el modo vuelo libre sin colisiones.')
    TriggerEvent('chat:addSuggestion', '/tpm', 'Teletransporte directo al punto de ruta marcado en el mapa.')
    TriggerEvent('chat:addSuggestion', '/tp', 'Teletransporte hacia un jugador o coordenadas específicas.', {
        { name = 'destino', help = 'ID del jugador o coordenadas X Y Z' }
    })
    TriggerEvent('chat:addSuggestion', '/bring', 'Teletransporta a un jugador directamente hacia tu posición.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/freeze', 'Congela o descongela físicamente a un jugador.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/car', 'Spawnea un vehículo en tu posición.', {
        { name = 'modelo', help = 'Nombre del vehículo (ej: adder, sultan)' }
    })
    TriggerEvent('chat:addSuggestion', '/dv', 'Elimina el vehículo actual o el más cercano en 5 metros.')
    TriggerEvent('chat:addSuggestion', '/kick', 'Expulsa a un jugador de la sesión.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'motivo', help = 'Razón de la expulsión' }
    })
    TriggerEvent('chat:addSuggestion', '/ban', 'Banea a un jugador con registro persistente en base de datos.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'horas', help = 'Duración en horas (0 = permanente)' },
        { name = 'motivo', help = 'Motivo de la sanción' }
    })
    TriggerEvent('chat:addSuggestion', '/unban', 'Levanta la sanción de una licencia baneada.', {
        { name = 'license', help = 'Identificador license:xxxxxxxx' }
    })
    TriggerEvent('chat:addSuggestion', '/anuncio', 'Emite un comunicado destacado para todo el servidor.', {
        { name = 'mensaje', help = 'Texto del anuncio' }
    })
end)
