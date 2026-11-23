# Luxury Loading Screen - Origen Bar & Spotify Edition
> **Desarrollado exclusivamente por Luxury Scripts**  
> *Pantalla de carga cinematográfica para FiveM con vídeo local MP4 de fondo, la icónica barra de carga estilo **Origen Loadingscreen** y reproductor interactivo de Spotify abajo a la derecha con Play, Pausa y visor de lista de canciones. 100% Gráficos Vectoriales SVG sin emojis.*

---

## Características Principales

1. **Barra de Carga Estilo Origen Loadingscreen:**
   - **Línea de Progreso Slim:** Pista delgada de `3.5px` con la clásica **chispa frontal brillante** (`origen-head-spark`) que recorre la línea e ilumina el avance.
   - **Porcentaje de Alta Precisión:** Grandes números geométricos con el símbolo `%` al estilo Origen.
   - **Borde de Acento Lateral:** Detalle en relieve dorado en el lateral izquierdo (`border-left: 3px solid var(--primary-color)`).
   - **Etapas Dinámicas:** `FASE 1 DE 4`, `FASE 2 DE 4`, `FASE 3 DE 4`, `FASE 4 DE 4` y `¡LISTO!`.
   - **Log en Tiempo Real:** Muestra el archivo o textura que FiveM está cargando en vivo.
   - **Sincronización Monotónica Estricta:** La barra solo avanza; nunca retrocede y una vez alcanza el 100% se detiene permanentemente (no se reinicia).
   - **Cero Emojis:** Todos los indicadores, iconos y estados utilizan gráficos vectoriales SVG limpios.

2. **Reproductor Spotify Abajo a la Derecha:**
   - Ubicado en la esquina inferior derecha.
   - **Controles:** Botón de Play / Pausa real y botón para pasar a la siguiente canción.
   - **Ver Lista:** Abre una tarjeta flotante de cristal esmerilado con la lista de canciones para seleccionar y reproducir cualquiera con un clic.
   - **Enlace a Spotify:** Botón para abrir la playlist oficial en Spotify.

3. **Vídeo Local MP4 a Pantalla Completa:**
   - Vídeo limpio alojado en `web/assets/video/background.mp4`.
   - Ajuste automático `object-fit: cover` para monitores 1080p, 2K, 4K y Ultrawide (21:9).

---

## Configuración Rápida (`web/config.js`)

Abre [config.js](file:///home/vertexdevelopement/luxury-loading/web/config.js):

```javascript
Music: {
    enabled: true,
    autoplay: true,
    defaultVolume: 25,
    spotifyLink: "https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM",
    playlistTitle: "Luxury Hits • Spotify",
    playlist: [
        {
            title: "Luxury Boulevard",
            artist: "Night Drive Beats",
            src: "assets/audio/luxury_ambience.mp3",
            duration: "03:45"
        }
    ]
}
```

---

## Cómo Probarlo en Navegador

Abre [index.html](file:///home/vertexdevelopement/luxury-loading/web/index.html) en tu navegador para ver la barra estilo Origen cargando del 0% al 100% (al llegar al 100% se queda fija y no se reinicia), pausar/reproducir música y desplegar la lista interactiva.

---

## Instalación en FiveM

1. Copia la carpeta `luxury-loading` a `resources/`.
2. Añade en tu `server.cfg`:
   ```cfg
   ensure luxury-loading
   ```
3. Reinicia tu servidor.
