# luxury_core (v1.0.0 - Qbox Architecture Standard)

Framework base definitivo para FiveM desarrollado bajo los estándares de arquitectura modular de **Qbox (`qbx_core`)**, con soporte nativo para **Lua 5.4**, **Arquitectura Proxy & Tunnel**, **OneSync Infinity Routing Buckets**, **Gangs independientes**, **Licencias**, **Base de Datos de Vehículos/Armas**, **ox_inventory**, **oxmysql**, **Puente Universal (ESX / QBCore / Qbox)** y **Motor Centinela Anti-Cheat / Anti-Dump**.

---

## 🏛️ Estructura Modular Qbox-Style

El core está estrictamente desacoplado por responsabilidades:

```
luxury_core/
├── fxmanifest.lua                  (v1.0.0 con exports universales)
├── config/
│   ├── shared.lua                  (Ajustes compartidos cliente/servidor)
│   ├── server.lua                  (Paycheck, autoguardado, buckets)
│   └── client.lua                  (Teclas y controles)
├── shared/
│   ├── jobs.lua                    (Trabajos legales con rangos y salarios)
│   ├── gangs.lua                   (Bandas y mafias ilegales independientes)
│   ├── vehicles.lua                (Registro de vehículos, marcas y maleteros)
│   └── weapons.lua                 (Armas, categorías y tipos de munición)
├── server/
│   ├── preflight.lua               (Comprobaciones de arranque y banner ASCII)
│   ├── security.lua                (Honeypot, HWID bans, C++ interceptors)
│   ├── admins.lua                  (Lista privada de administradores)
│   ├── proxy.lua                   (Interfaz Proxy & Tunnel del servidor)
│   ├── buckets.lua                 (Gestor de dimensiones e instancias de OneSync)
│   ├── licenses.lua                (Sistema de licencias de conducir, armas, etc.)
│   ├── player.lua                  (Clase Player con metatables completas)
│   ├── functions.lua               (Funciones de utilidad GetPlayer, GetPlayers)
│   ├── events.lua                  (Manejadores de eventos de red)
│   ├── commands.lua                (Comandos de rol: /dinero, /trabajo, /id, /banda)
│   ├── inventory.lua               (Puente con ox_inventory)
│   ├── society.lua                 (Fondos de empresa y menú de jefes)
│   ├── status.lua                  (Desgaste de hambre y sed)
│   ├── death.lua                   (Gestión médica y facturación de hospital)
│   ├── admin.lua                   (Suite administrativa completa)
│   └── main.lua                    (Base de datos auto-migrable y bucles)
├── client/
│   ├── security.lua                (Centinela Anti-Godmode, Speedhack, Armas)
│   ├── proxy.lua                   (Interfaz Proxy & Tunnel del cliente)
│   ├── functions.lua               (GetClosestPlayer, GetClosestVehicle)
│   ├── player.lua                  (Datos del LocalPlayer y exports)
│   ├── events.lua                  (Spawn seguro con colisiones)
│   ├── loops.lua                   (Sincronización periódica de coordenadas)
│   ├── death.lua                   (Coma, bleedout y postfx cinematográfico)
│   ├── status.lua                  (Vigilante de inanición y deshidratación)
│   ├── suggestions.lua             (Autocompletado nativo del chat)
│   ├── admin.lua                   (Noclip, tpm, car, dv, freeze)
│   └── main.lua                    (Punto de entrada de cliente)
├── bridge/                         (Emuladores de ESX, QBCore y Qbox)
├── bridges/                        (Shims autónomos para es_extended, qb-core y qbx_core)
└── luxury_lib/                     (Librería Proxy, Tunnel, caché de 0.00ms y callbacks Await)
```

---

## 🏴‍☠️ 1. Sistema de Bandas (Gangs) Separado de Trabajos
En `luxury_core`, un personaje puede ser **Policía, Médico o Mecánico (su `job`)** y a la vez pertenecer a una **Banda o Mafia (su `gang`)**:
* Definido en [`shared/gangs.lua`](file:///home/vertexdevelopement/luxury_core/shared/gangs.lua) con rangos y marca de líder (`isBoss`).
* Métodos en `Player`: `player:setGang(name, grade)`, `player:getGang()`.
* Comandos: `/banda`, `/contratarBanda [id]`, `/despedirBanda [id]`.

---

## 🪪 2. Sistema de Licencias de Personaje
Metadatos estructurados en `player.charinfo.licences`:
* Licencias incluidas: `driver` (conducir), `weapon` (armas), `hunting` (caza), `pilot` (aviación).
* Métodos en `Player`: `player:hasLicense(type)`, `player:grantLicense(type)`, `player:revokeLicense(type)`, `player:getLicenses()`.
* Comandos policiales/administrativos: `/darLicencia [id] [tipo]`, `/quitarLicencia [id] [tipo]`.
* Visibles automáticamente al usar `/id`.

---

## 🌌 3. Gestor de Dimensiones (Routing Buckets OneSync)
Permite aislar jugadores en instancias privadas (habitaciones, concesionarios, creación de personaje):
* [`server/buckets.lua`](file:///home/vertexdevelopement/luxury_core/server/buckets.lua).
* Métodos y Exports: `SetPlayerBucket(src, bucket)`, `GetPlayerBucket(src)`, `ResetPlayerBucket(src)`.
* Sincronizado en State Bag `Player(src).state.instance`.

---

## 🏎️ 4. Base de Datos Compartida de Vehículos y Armas
* [`shared/vehicles.lua`](file:///home/vertexdevelopement/luxury_core/shared/vehicles.lua): Catálogo completo con modelo, marca, precio, categoría y capacidad de maletero (`GetVehicleData(modelOrHash)`).
* [`shared/weapons.lua`](file:///home/vertexdevelopement/luxury_core/shared/weapons.lua): Catálogo de armas, categorías y tipos de munición (`GetWeaponData(nameOrHash)`).

---

## ⚡ 5. Manejo Completo por Proxy & Tunnel
* **Proxy**: `local Luxury = Proxy.getInterface('luxury')` (comunicación inter-recursos local sin coste de red).
* **Tunnel**: `local LuxuryServer = Tunnel.getInterface('luxury')` (llamadas remotas resueltas linealmente con `Citizen.Await`).
