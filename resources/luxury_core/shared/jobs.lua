-- luxury_core: Registro de Trabajos, Rangos y Salarios
Jobs = {}

Jobs['unemployed'] = {
    label = 'Desempleado',
    defaultDuty = true,
    grades = {
        [0] = { name = 'unemployed', label = 'En el paro', salary = 100 }
    }
}

Jobs['police'] = {
    label = 'Policía Nacional',
    defaultDuty = true,
    grades = {
        [0] = { name = 'cadet', label = 'Cadete', salary = 350 },
        [1] = { name = 'officer', label = 'Oficial', salary = 500 },
        [2] = { name = 'sergeant', label = 'Sargento', salary = 750 },
        [3] = { name = 'lieutenant', label = 'Teniente', salary = 950 },
        [4] = { name = 'chief', label = 'Comisario Jefe', salary = 1300, isBoss = true }
    }
}

Jobs['ambulance'] = {
    label = 'Servicios Médicos (EMS)',
    defaultDuty = true,
    grades = {
        [0] = { name = 'intern', label = 'Enfermero en Prácticas', salary = 300 },
        [1] = { name = 'paramedic', label = 'Paramédico', salary = 550 },
        [2] = { name = 'doctor', label = 'Médico Titular', salary = 800 },
        [3] = { name = 'surgeon', label = 'Cirujano Jefe', salary = 1100, isBoss = true }
    }
}

Jobs['mechanic'] = {
    label = 'Taller Mecánico',
    defaultDuty = true,
    grades = {
        [0] = { name = 'apprentice', label = 'Aprendiz', salary = 250 },
        [1] = { name = 'mechanic', label = 'Mecánico', salary = 450 },
        [2] = { name = 'specialist', label = 'Jefe de Taller', salary = 700, isBoss = true }
    }
}

Jobs['taxi'] = {
    label = 'Downtown Cab Co.',
    defaultDuty = true,
    grades = {
        [0] = { name = 'driver', label = 'Conductor', salary = 250 },
        [1] = { name = 'boss', label = 'Gerente', salary = 500, isBoss = true }
    }
}

-- Función utilitaria compartida para consultar información de un trabajo
function GetJobInfo(jobName, grade)
    if not jobName or type(jobName) ~= 'string' then return nil end
    grade = tonumber(grade) or 0
    local job = Jobs[jobName]

    if job then
        local gradeData = job.grades and (job.grades[grade] or job.grades[0])
        return {
            name = jobName,
            label = job.label or jobName,
            grade = grade,
            grade_name = gradeData and gradeData.name or tostring(grade),
            grade_label = gradeData and gradeData.label or ('Rango ' .. grade),
            salary = gradeData and gradeData.salary or 150,
            isBoss = gradeData and gradeData.isBoss or false
        }
    else
        -- Fallback dinámico para scripts de terceros o trabajos no predefinidos en Jobs
        local formattedLabel = jobName:gsub('^%l', string.upper)
        return {
            name = jobName,
            label = formattedLabel,
            grade = grade,
            grade_name = tostring(grade),
            grade_label = 'Rango ' .. grade,
            salary = 200,
            isBoss = (grade >= 3)
        }
    end
end
