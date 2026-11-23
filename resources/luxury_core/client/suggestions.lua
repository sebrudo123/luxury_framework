-- luxury_core: Sugerencias y Autocompletado del Chat (Client-side Suggestions)

CreateThread(function()
    Wait(1000)

    -- Jugador y Economía
    TriggerEvent('chat:addSuggestion', '/dinero', 'Muestra tu saldo actual en efectivo y en el banco.')
    TriggerEvent('chat:addSuggestion', '/trabajo', 'Muestra tu trabajo, rango laboral y sueldo.')
    TriggerEvent('chat:addSuggestion', '/banda', 'Muestra tu banda o mafia y tu rango dentro de ella.')
    TriggerEvent('chat:addSuggestion', '/id', 'Muestra tu documento nacional de identidad (DNI/CitizenID).')

    -- Comandos de Roleplay
    TriggerEvent('chat:addSuggestion', '/me', 'Realiza una acción física de tu personaje.', {
        { name = 'acción', help = 'Acción detallada del personaje' }
    })
    TriggerEvent('chat:addSuggestion', '/do', 'Describe un suceso del entorno o consecuencia visible.', {
        { name = 'situación', help = 'Descripción del entorno o situación' }
    })
    TriggerEvent('chat:addSuggestion', '/ooc', 'Envía un mensaje fuera de rol a jugadores cercanos.', {
        { name = 'mensaje', help = 'Texto fuera de personaje' }
    })
    TriggerEvent('chat:addSuggestion', '/b', 'Alias corto de /ooc.', {
        { name = 'mensaje', help = 'Texto fuera de personaje' }
    })
    TriggerEvent('chat:addSuggestion', '/twt', 'Publica un tweet visible para todos en la ciudad.', {
        { name = 'mensaje', help = 'Contenido del tweet' }
    })
    TriggerEvent('chat:addSuggestion', '/tweet', 'Publica un tweet en la red social.', {
        { name = 'mensaje', help = 'Contenido del tweet' }
    })
    TriggerEvent('chat:addSuggestion', '/anon', 'Envía un mensaje completamente anónimo en la red profunda.', {
        { name = 'mensaje', help = 'Mensaje anónimo' }
    })

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
    TriggerEvent('chat:addSuggestion', '/contratarBanda', 'Recluta a un jugador en tu banda criminal.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/despedirBanda', 'Expulsa a un miembro de tu banda.', {
        { name = 'id', help = 'ID del jugador' }
    })

    -- Comandos de Administración
    TriggerEvent('chat:addSuggestion', '/setjob', 'Asigna un trabajo y rango específico a un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'trabajo', help = 'Nombre técnico del trabajo (ej: police, mechanic)' },
        { name = 'rango', help = 'Número del rango (0, 1, 2...)' }
    })
    TriggerEvent('chat:addSuggestion', '/setgang', 'Asigna una banda y rango específico a un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'banda', help = 'Nombre de la banda (ej: ballas, families, vagos)' },
        { name = 'rango', help = 'Número del rango (0, 1, 2...)' }
    })
    TriggerEvent('chat:addSuggestion', '/givemoney', 'Añade fondos a la cuenta de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'cuenta', help = 'cash | bank | crypto' },
        { name = 'cantidad', help = 'Monto a transferir' }
    })
    TriggerEvent('chat:addSuggestion', '/setmoney', 'Establece el dinero exacto en la cuenta de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'cuenta', help = 'cash | bank | crypto' },
        { name = 'cantidad', help = 'Monto a fijar' }
    })
    TriggerEvent('chat:addSuggestion', '/giveitem', 'Entrega un ítem al inventario de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'ítem', help = 'Nombre técnico del ítem' },
        { name = 'cantidad', help = 'Cantidad a entregar' }
    })
    TriggerEvent('chat:addSuggestion', '/clearinventory', 'Vacía por completo el inventario de un jugador.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/setGroup', 'Asigna y persiste el rango administrativo de un jugador.', {
        { name = 'id', help = 'ID del jugador' },
        { name = 'grupo', help = 'user | mod | admin' }
    })
    TriggerEvent('chat:addSuggestion', '/heal', 'Restaura la salud, armadura y necesidades al 100%.', {
        { name = 'id', help = 'ID del jugador (opcional)' }
    })
    TriggerEvent('chat:addSuggestion', '/revive', 'Revive a un jugador inconsciente.', {
        { name = 'id', help = 'ID del jugador (opcional, por defecto tú mismo)' }
    })
    TriggerEvent('chat:addSuggestion', '/goto', 'Teletranspórtate instantáneamente hacia la posición de un jugador.', {
        { name = 'id', help = 'ID del jugador objetivo' }
    })
    TriggerEvent('chat:addSuggestion', '/bring', 'Teletransporta a un jugador directamente hacia tu posición.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/tp', 'Teletransporte hacia un jugador o coordenadas específicas.', {
        { name = 'destino', help = 'ID del jugador o coordenadas X Y Z' }
    })
    TriggerEvent('chat:addSuggestion', '/tpm', 'Teletransporte directo al punto de ruta marcado en el mapa.')
    TriggerEvent('chat:addSuggestion', '/noclip', 'Activa o desactiva el modo vuelo libre sin colisiones.')
    TriggerEvent('chat:addSuggestion', '/freeze', 'Congela o descongela físicamente a un jugador.', {
        { name = 'id', help = 'ID del jugador' }
    })
    TriggerEvent('chat:addSuggestion', '/car', 'Spawnea un vehículo en tu posición.', {
        { name = 'modelo', help = 'Nombre del vehículo (ej: adder, sultan)' }
    })
    TriggerEvent('chat:addSuggestion', '/dv', 'Elimina el vehículo actual o los vehículos en un radio.', {
        { name = 'radio', help = 'Radio en metros (opcional)' }
    })
    TriggerEvent('chat:addSuggestion', '/fix', 'Repara, limpia y arregla las ruedas del vehículo.')
    TriggerEvent('chat:addSuggestion', '/reparar', 'Alias de /fix para reparar vehículos.')
    TriggerEvent('chat:addSuggestion', '/coords', 'Muestra coordenadas vector3 y vector4 en consola F8 y chat.')
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
