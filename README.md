# Luxury Framework - Official GitHub Repository & txAdmin Recipe

Ecosistema completo y modular para servidores FiveM de alta capacidad, optimizado a 0.00ms resmon y diseñado para despliegue directo mediante **txAdmin Remote URL Template** (idéntico a ESX Legacy o QBCore).

---

## Despliegue Instantáneo en txAdmin (Remote URL)

1. Abre tu panel de control de **txAdmin**.
2. En la configuración de nuevo servidor (**Server Deployer**), selecciona **Remote URL Template**.
3. Pega la URL directa de la receta:
   ```text
   https://raw.githubusercontent.com/Sebrudo123/luxury_framework/main/recipe.yaml
   ```
4. Introduce tu clave de licencia de FiveM Keymaster y los datos de tu base de datos MariaDB / MySQL.
5. Haz clic en **Run Recipe**. txAdmin descargará automáticamente los recursos base de CFX, la librería `oxmysql`, todo el paquete de Luxury Framework desde GitHub e importará el esquema SQL.

---

## Estructura del Repositorio

```text
luxury_framework/
├── recipe.yaml              # Receta oficial txAdmin Engine v3
├── install.sql              # Esquema de base de datos consolidado (oxmysql)
├── server.cfg               # Configuración optimizada con orden de arranque
├── README.md                # Documentación oficial
├── push_to_github.sh        # Script automatizado de actualización a GitHub
└── resources/               # Todos los recursos del framework
    ├── luxury_lib           # Librería base y utilidades
    ├── luxury_core          # Núcleo del servidor, seguridad y jugadores
    ├── luxury_banking       # Sistema bancario y transferencias
    ├── luxury_garage        # Garajes, depósitos y llaves
    ├── luxury_hud           # HUD modular con velocímetro e indicadores
    ├── luxury_radial        # Menú radial interactivo de accesos rápidos
    ├── luxury_notify        # Notificaciones flotantes de alta prioridad
    ├── luxury_loading       # Pantalla de carga interactiva
    └── luxury_multicharacter # Selector multicarácter con cinemáticas
```

---

## Cómo Publicar o Actualizar en GitHub

Si realizas cambios en el código local:

```bash
cd /home/vertexdevelopement/luxury_framework
chmod +x push_to_github.sh
./push_to_github.sh
git push -u origin main
```
