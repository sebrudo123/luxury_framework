-- luxury_core: Registro de Bandas, Mafias y Facciones Ilegales (Gangs System)
Gangs = {}

Gangs['none'] = {
    label = 'Ninguna',
    grades = {
        [0] = { name = 'none', label = 'Sin banda', isBoss = false }
    }
}

Gangs['ballas'] = {
    label = 'East Side Ballas',
    grades = {
        [0] = { name = 'young', label = 'Novato', isBoss = false },
        [1] = { name = 'shooter', label = 'Tirador', isBoss = false },
        [2] = { name = 'enforcer', label = 'Lugarteniente', isBoss = false },
        [3] = { name = 'boss', label = 'Líder / OG', isBoss = true }
    }
}

Gangs['families'] = {
    label = 'Chamberlain Gangster Families',
    grades = {
        [0] = { name = 'young', label = 'Iniciado', isBoss = false },
        [1] = { name = 'hustler', label = 'Traficante', isBoss = false },
        [2] = { name = 'enforcer', label = 'Veterano', isBoss = false },
        [3] = { name = 'boss', label = 'Líder / Jefe', isBoss = true }
    }
}

Gangs['vagos'] = {
    label = 'Los Santos Vagos',
    grades = {
        [0] = { name = 'novato', label = 'Novato', isBoss = false },
        [1] = { name = 'soldado', label = 'Soldado', isBoss = false },
        [2] = { name = 'mano_derecha', label = 'Mano Derecha', isBoss = false },
        [3] = { name = 'patron', label = 'El Patrón', isBoss = true }
    }
}

Gangs['marabunta'] = {
    label = 'Marabunta Grande',
    grades = {
        [0] = { name = 'iniciado', label = 'Iniciado', isBoss = false },
        [1] = { name = 'gatillero', label = 'Gatillero', isBoss = false },
        [2] = { name = 'subjefe', label = 'Subjefe', isBoss = false },
        [3] = { name = 'jefe', label = 'Jefe', isBoss = true }
    }
}

Gangs['lostmc'] = {
    label = 'The Lost MC',
    grades = {
        [0] = { name = 'prospect', label = 'Prospect', isBoss = false },
        [1] = { name = 'member', label = 'Miembro Oficial', isBoss = false },
        [2] = { name = 'sergeant', label = 'Sargento de Armas', isBoss = false },
        [3] = { name = 'president', label = 'Presidente', isBoss = true }
    }
}

Gangs['cartel'] = {
    label = 'Cártel de Madrazo',
    grades = {
        [0] = { name = 'sicario_jr', label = 'Sicario Jr', isBoss = false },
        [1] = { name = 'sicario', label = 'Sicario', isBoss = false },
        [2] = { name = 'comandante', label = 'Comandante', isBoss = false },
        [3] = { name = 'capo', label = 'Capo', isBoss = true }
    }
}

--- Consulta la información de una banda y rango
-- @param gangName string
-- @param grade number|nil
-- @return table|nil
function GetGangInfo(gangName, grade)
    local gang = Gangs[gangName] or Gangs['none']
    grade = tonumber(grade) or 0
    local gradeData = gang.grades[grade] or gang.grades[0] or { name = 'none', label = 'Sin rango', isBoss = false }

    return {
        name = gangName,
        label = gang.label,
        grade = grade,
        grade_name = gradeData.name,
        grade_label = gradeData.label,
        isBoss = gradeData.isBoss or false
    }
end
