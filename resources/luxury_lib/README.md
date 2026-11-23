# luxury_lib

Librería de utilidades de alto rendimiento y arquitectura moderna para el ecosistema **Luxury Framework** en FiveM.

## Características

- ⚡ **Lua 5.4 nativo** (`lua54 'yes'`).
- 🔄 **Sistema de Callbacks Bidireccional** con soporte para `promise` / `Citizen.Await` (código lineal sin anidamiento infinito de callbacks).
- 🛡️ **Matemáticas y Sanitización Estricta** (inmune a exploits de `NaN`, `Infinity` o valores negativos).
- 📦 **Caché Reactivo del Cliente** (`Luxury.Cache.ped`, `coords`, `vehicle`, etc. con un coste menor a 0.01ms CPU).
- 🎬 **Streaming Helper** con promesas y timeout para cargar modelos (`RequestModel`) y diccionarios de animación (`RequestAnimDict`).
- 🔔 **Sistema de Notificaciones** unificado y desacoplado de la UI.

---

## Cómo usarlo en otros recursos

### 1. Importación rápida en `fxmanifest.lua`:
```lua
client_script '@luxury_lib/init.lua' -- o server_script
```

O vía exports:
```lua
local Luxury = exports['luxury_lib']:GetLib()
```

---

## Ejemplos de uso

### Callbacks con Await (Sintaxis limpia)
**En el Servidor:**
```lua
Luxury.RegisterCallback('luxury_garage:getVehicles', function(src, cb)
    local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE owner = ?', { src })
    cb(vehicles)
end)
```

**En el Cliente:**
```lua
-- Espera la respuesta de forma síncrona sin congelar el juego:
local misCoches = Luxury.AwaitCallback('luxury_garage:getVehicles')
print("Tengo " .. #misCoches .. " vehículos")
```

### Caché del Cliente
```lua
-- En lugar de hacer PlayerPedId() y GetEntityCoords() 100 veces por segundo:
local ped = Luxury.Cache.ped
local coords = Luxury.Cache.coords
local inVeh = Luxury.Cache.inVehicle
```

### Sanitización Segura de Dinero
```lua
-- Retorna un entero limpio o el valor por defecto (0), bloqueando NaN y exploits
local dineroSeguro = Luxury.Math.SanitizeNumber(inputDelUsuario, 1, 1000000, 0)
```
