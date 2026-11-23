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
    local job = Jobs[jobName]
    if not job then return nil end

    grade = tonumber(grade) or 0
    local gradeData = job.grades[grade] or job.grades[0]

    return {
        name = jobName,
        label = job.label,
        grade = grade,
        grade_name = gradeData and gradeData.name or 'default',
        grade_label = gradeData and gradeData.label or 'Rango ' .. grade,
        salary = gradeData and gradeData.salary or 0,
        isBoss = gradeData and gradeData.isBoss or false
    }
end
