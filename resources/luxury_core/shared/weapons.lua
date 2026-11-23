-- luxury_core: Registro Compartido de Armas y Calibres (Weapons System)
Weapons = {}

Weapons['WEAPON_UNARMED'] = { name = 'WEAPON_UNARMED', label = 'Puños', category = 'melee', ammo = nil }
Weapons['WEAPON_KNIFE'] = { name = 'WEAPON_KNIFE', label = 'Cuchillo', category = 'melee', ammo = nil }
Weapons['WEAPON_BAT'] = { name = 'WEAPON_BAT', label = 'Bate de Béisbol', category = 'melee', ammo = nil }
Weapons['WEAPON_FLASHLIGHT'] = { name = 'WEAPON_FLASHLIGHT', label = 'Linterna', category = 'melee', ammo = nil }
Weapons['WEAPON_PISTOL'] = { name = 'WEAPON_PISTOL', label = 'Pistola Beretta 9mm', category = 'pistol', ammo = 'AMMO_PISTOL' }
Weapons['WEAPON_COMBATPISTOL'] = { name = 'WEAPON_COMBATPISTOL', label = 'Pistola de Combate', category = 'pistol', ammo = 'AMMO_PISTOL' }
Weapons['WEAPON_APPISTOL'] = { name = 'WEAPON_APPISTOL', label = 'Pistola Automática (AP)', category = 'pistol', ammo = 'AMMO_PISTOL' }
Weapons['WEAPON_STUNGUN'] = { name = 'WEAPON_STUNGUN', label = 'Táser Policial', category = 'handgun', ammo = nil }
Weapons['WEAPON_MICROSMG'] = { name = 'WEAPON_MICROSMG', label = 'Micro SMG (Uzi)', category = 'smg', ammo = 'AMMO_SMG' }
Weapons['WEAPON_SMG'] = { name = 'WEAPON_SMG', label = 'Subfusil MP5', category = 'smg', ammo = 'AMMO_SMG' }
Weapons['WEAPON_ASSAULTRIFLE'] = { name = 'WEAPON_ASSAULTRIFLE', label = 'Fusil AK-47', category = 'rifle', ammo = 'AMMO_RIFLE' }
Weapons['WEAPON_CARBINERIFLE'] = { name = 'WEAPON_CARBINERIFLE', label = 'Carabina M4A1', category = 'rifle', ammo = 'AMMO_RIFLE' }
Weapons['WEAPON_PUMPSHOTGUN'] = { name = 'WEAPON_PUMPSHOTGUN', label = 'Escopeta de Corredera', category = 'shotgun', ammo = 'AMMO_SHOTGUN' }
Weapons['WEAPON_SNIPERRIFLE'] = { name = 'WEAPON_SNIPERRIFLE', label = 'Fusil de Francotirador', category = 'sniper', ammo = 'AMMO_SNIPER' }

--- Obtiene la información de un arma por su nombre o hash
function GetWeaponData(weaponNameOrHash)
    if type(weaponNameOrHash) == 'number' then
        for _, w in pairs(Weapons) do
            if joaat(w.name) == weaponNameOrHash then return w end
        end
        return nil
    elseif type(weaponNameOrHash) == 'string' then
        return Weapons[weaponNameOrHash:upper()]
    end
    return nil
end
