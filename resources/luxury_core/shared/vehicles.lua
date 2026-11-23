-- luxury_core: Base de Datos y Registro Compartido de Vehículos
Vehicles = {}

Vehicles['adder'] = { name = 'Adder', brand = 'Truffade', model = 'adder', price = 1000000, category = 'super', trunkSlots = 25, trunkWeight = 40000 }
Vehicles['sultan'] = { name = 'Sultan', brand = 'Karin', model = 'sultan', price = 25000, category = 'sports', trunkSlots = 35, trunkWeight = 60000 }
Vehicles['sultanrs'] = { name = 'Sultan RS', brand = 'Karin', model = 'sultanrs', price = 75000, category = 'super', trunkSlots = 30, trunkWeight = 50000 }
Vehicles['banshee'] = { name = 'Banshee', brand = 'Bravado', model = 'banshee', price = 90000, category = 'sports', trunkSlots = 25, trunkWeight = 40000 }
Vehicles['zentorno'] = { name = 'Zentorno', brand = 'Pegassi', model = 'zentorno', price = 725000, category = 'super', trunkSlots = 20, trunkWeight = 35000 }
Vehicles['kuruma'] = { name = 'Kuruma', brand = 'Karin', model = 'kuruma', price = 45000, category = 'sports', trunkSlots = 40, trunkWeight = 70000 }
Vehicles['panto'] = { name = 'Panto', brand = 'Benefactor', model = 'panto', price = 8500, category = 'compacts', trunkSlots = 15, trunkWeight = 25000 }
Vehicles['futo'] = { name = 'Futo', brand = 'Karin', model = 'futo', price = 12000, category = 'coupes', trunkSlots = 30, trunkWeight = 50000 }
Vehicles['baller'] = { name = 'Baller', brand = 'Gallivanter', model = 'baller', price = 35000, category = 'suvs', trunkSlots = 50, trunkWeight = 90000 }
Vehicles['dubsta'] = { name = 'Dubsta', brand = 'Benefactor', model = 'dubsta', price = 45000, category = 'suvs', trunkSlots = 50, trunkWeight = 90000 }
Vehicles['sandking'] = { name = 'Sandking XL', brand = 'Vapid', model = 'sandking', price = 38000, category = 'offroad', trunkSlots = 60, trunkWeight = 120000 }
Vehicles['sanchez'] = { name = 'Sanchez', brand = 'Maibatsu', model = 'sanchez', price = 8000, category = 'motorcycles', trunkSlots = 10, trunkWeight = 15000 }
Vehicles['bati'] = { name = 'Bati 801', brand = 'Pegassi', model = 'bati', price = 15000, category = 'motorcycles', trunkSlots = 10, trunkWeight = 15000 }
Vehicles['police'] = { name = 'Stanier Cruiser', brand = 'Vapid', model = 'police', price = 0, category = 'emergency', trunkSlots = 60, trunkWeight = 100000 }
Vehicles['police2'] = { name = 'Buffalo Cruiser', brand = 'Bravado', model = 'police2', price = 0, category = 'emergency', trunkSlots = 60, trunkWeight = 100000 }
Vehicles['ambulance'] = { name = 'Ambulancia EMS', brand = 'Brute', model = 'ambulance', price = 0, category = 'emergency', trunkSlots = 70, trunkWeight = 150000 }
Vehicles['taxi'] = { name = 'Taxi Cab', brand = 'Vapid', model = 'taxi', price = 18000, category = 'service', trunkSlots = 45, trunkWeight = 80000 }

--- Obtiene la información técnica y comercial de un vehículo por modelo o hash
-- @param model string|number: Modelo en texto o Hash numérico
-- @return table|nil
function GetVehicleData(model)
    if type(model) == 'number' then
        for _, v in pairs(Vehicles) do
            if joaat(v.model) == model then return v end
        end
        return nil
    elseif type(model) == 'string' then
        return Vehicles[model:lower()]
    end
    return nil
end
