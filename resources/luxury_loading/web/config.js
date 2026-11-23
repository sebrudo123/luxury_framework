/**
 * ====================================================================
 *                 LUXURY SCRIPTS - LOADING SCREEN CONFIG
 * ====================================================================
 * Archivo de configuración central.
 * Aquí el dueño del servidor puede:
 * 1. Poner el link de Spotify y configurar las canciones de la lista.
 * 2. Ajustar el vídeo local MP4 de fondo.
 * 3. Personalizar textos, logo y colores (Sin emojis, 100% vectorial).
 * ====================================================================
 */

const Config = {
    // ----------------------------------------------------------------
    // 1. INFORMACIÓN DEL SERVIDOR & MARCA
    // ----------------------------------------------------------------
    Server: {
        name: "LUXURY",
        nameHighlight: "ROLEPLAY",
        tagline: "DONDE EL LUJO Y EL ROL ALCANZAN SU MÁXIMO NIVEL",
        logo: "assets/images/logo.svg", // Ruta a tu logo (SVG, PNG, WebP)
        badge: "V3.0 • PREMIUM",
        discordUrl: "https://discord.gg/luxury-scripts"
    },

    // ----------------------------------------------------------------
    // 2. REPRODUCTOR DE MÚSICA & SPOTIFY (ABAJO A LA DERECHA)
    // ----------------------------------------------------------------
    Music: {
        enabled: true,
        autoplay: true, // Reproducir al iniciar
        defaultVolume: 25, // Volumen inicial de 0 a 100
        
        // Link oficial de Spotify (se abre al hacer clic en el botón de Spotify en la lista)
        spotifyLink: "https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM",
        playlistTitle: "Luxury Hits • Spotify",

        // Lista de canciones reproducibles (con Play, Pausa y selector de lista):
        playlist: [
            {
                id: 1,
                title: "Luxury Boulevard",
                artist: "Night Drive Beats",
                src: "assets/audio/luxury_ambience.mp3",
                duration: "03:45"
            },
            {
                id: 2,
                title: "Midnight Vice",
                artist: "Synthwave Deluxe",
                src: "assets/audio/midnight_vice.mp3",
                duration: "04:12"
            },
            {
                id: 3,
                title: "Grand Royale",
                artist: "Chillhop Sunset",
                src: "assets/audio/grand_royale.mp3",
                duration: "03:18"
            },
            {
                id: 4,
                title: "Obsidian Nights",
                artist: "Downtown Vibe",
                src: "assets/audio/obsidian_nights.mp3",
                duration: "03:55"
            }
        ]
    },

    // ----------------------------------------------------------------
    // 3. VÍDEO LOCAL MP4 DE FONDO
    // ----------------------------------------------------------------
    // Coloca tu vídeo MP4 en la carpeta: web/assets/video/background.mp4
    Background: {
        videoSource: "assets/video/background.mp4",
        overlayDarkness: 0.40 // Oscuridad sobre el vídeo (0.0 a 1.0)
    },

    // ----------------------------------------------------------------
    // 4. ESTILO & COLORES DE ALTA GAMA
    // ----------------------------------------------------------------
    Theme: {
        primaryColor: "#D4AF37", // Color Dorado Luxury
        primaryGlow: "rgba(212, 175, 55, 0.7)",
        enableCustomCursor: true
    },

    // ----------------------------------------------------------------
    // 5. CONSEJOS ROTATIVOS (SIN EMOJIS, CON ICONO SVG)
    // ----------------------------------------------------------------
    Tips: {
        interval: 4500, // Cada cuánto cambia el tip en ms
        items: [
            "Vincula tu cuenta de Discord para sincronizar tus permisos en la ciudad.",
            "Los vehículos abandonados en zonas prohibidas serán remolcados al depósito.",
            "Ante cualquier inconveniente en el rol, utiliza el comando /report en el chat.",
            "Valora la vida de tu personaje por encima de cualquier situación.",
            "Puedes pausar la música o cambiar de canción en el reproductor de abajo a la derecha.",
            "Guarda tu dinero en las sucursales bancarias autorizadas para mayor seguridad."
        ]
    },

    // ----------------------------------------------------------------
    // 6. MODO SIMULACIÓN PARA PROBAR EN NAVEGADOR (CHROME / EDGE / FIREFOX)
    // ----------------------------------------------------------------
    Simulation: {
        enabled: true,
        duration: 9000,
        loop: false // NUNCA se reinicia al llegar al 100%, se queda en 100%
    }
};
