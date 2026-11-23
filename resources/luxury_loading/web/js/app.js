/**
 * ====================================================================
 *                 LUXURY SCRIPTS - CINEMATIC CORE
 * ====================================================================
 * Motor optimizado para FiveM:
 * 1. Barra de carga Signature estilo Origen Loadingscreen con chispa.
 * 2. Reproductor Spotify abajo a la derecha con Play, Pausa, Siguiente
 *    y tarjeta desplegable interactiva para ver y seleccionar canciones.
 * 3. Vídeo local MP4 en bucle cinematográfico.
 * 4. Carga sincronizada estrictamente monotónica (NUNCA retrocede ni se reinicia).
 * 5. Cero emojis: 100% iconos vectoriales SVG.
 * ====================================================================
 */

document.addEventListener("DOMContentLoaded", () => {
    LuxuryApp.init();
});

const LuxuryApp = {
    currentProgress: 0,
    targetProgress: 0,
    isInFiveM: false,
    isCompleted: false,
    currentTipIndex: 0,

    // Estado del reproductor de música
    currentTrackIndex: 0,
    isPlaying: false,
    audioElement: null,
    audioContext: null,
    synthInterval: null,
    isPopoverOpen: false,

    // ----------------------------------------------------------------
    // INICIALIZACIÓN
    // ----------------------------------------------------------------
    init() {
        this.applyTheme();
        this.initBranding();
        this.initLocalVideo();
        this.initMusicPlayer();
        this.initDiscordAction();
        this.initTipsRotator();
        this.initCustomCursor();
        this.initProgressLerpLoop();
        this.initFiveMListener();
        this.detectEnvironment();
    },

    // ----------------------------------------------------------------
    // 1. TEMA Y COLORES DINÁMICOS
    // ----------------------------------------------------------------
    applyTheme() {
        if (!Config.Theme) return;
        const root = document.documentElement;

        if (Config.Theme.primaryColor) {
            root.style.setProperty('--primary-color', Config.Theme.primaryColor);
        }
        if (Config.Theme.primaryGlow) {
            root.style.setProperty('--primary-glow', Config.Theme.primaryGlow);
        }

        const vignette = document.getElementById("cinematic-vignette");
        if (vignette && typeof Config.Background.overlayDarkness === "number") {
            const d = Config.Background.overlayDarkness;
            vignette.style.background = `radial-gradient(circle at center, rgba(8, 8, 10, ${d * 0.3}) 0%, rgba(8, 8, 10, ${d}) 65%, rgba(4, 4, 5, 0.95) 100%)`;
        }
    },

    // ----------------------------------------------------------------
    // 2. MARCA DEL SERVIDOR
    // ----------------------------------------------------------------
    initBranding() {
        const s = Config.Server;
        if (!s) return;

        const serverNameEl = document.getElementById("server-name");
        const highlightEl = document.getElementById("server-name-highlight");
        const taglineEl = document.getElementById("server-tagline");
        const badgeEl = document.getElementById("server-badge");
        const logoEl = document.getElementById("server-logo");

        if (serverNameEl && s.name) serverNameEl.textContent = s.name;
        if (highlightEl && s.nameHighlight) highlightEl.textContent = s.nameHighlight;
        if (taglineEl && s.tagline) taglineEl.textContent = s.tagline;
        if (badgeEl && s.badge) badgeEl.textContent = s.badge;
        if (logoEl && s.logo) logoEl.src = s.logo;
    },

    // ----------------------------------------------------------------
    // 3. VÍDEO LOCAL MP4
    // ----------------------------------------------------------------
    initLocalVideo() {
        const bgConf = Config.Background;
        const videoEl = document.getElementById("bg-local-video");
        if (!videoEl || !bgConf) return;

        const videoSrc = bgConf.videoSource || "assets/video/background.mp4";
        videoEl.src = videoSrc;
        videoEl.muted = true;

        const playPromise = videoEl.play();
        if (playPromise !== undefined) {
            playPromise.catch(() => {
                // Manejo de restricciones de autoplay del navegador
            });
        }
    },

    // ----------------------------------------------------------------
    // 4. REPRODUCTOR SPOTIFY ABAJO A LA DERECHA (PLAY, PAUSA, LISTA)
    // ----------------------------------------------------------------
    initMusicPlayer() {
        const m = Config.Music;
        this.audioElement = document.getElementById("audio-engine");
        if (!m || !m.enabled || !m.playlist || m.playlist.length === 0) {
            const playerBox = document.querySelector(".bottom-right-player-wrapper");
            if (playerBox) playerBox.style.display = "none";
            return;
        }

        const btnPlay = document.getElementById("btn-toggle-play");
        const btnNext = document.getElementById("btn-next-track");
        const btnList = document.getElementById("btn-toggle-list");
        const btnClose = document.getElementById("btn-close-popover");
        const popoverTitle = document.getElementById("popover-playlist-title");
        const spotifyLinkBtn = document.getElementById("btn-open-spotify-link");

        if (popoverTitle && m.playlistTitle) {
            popoverTitle.textContent = m.playlistTitle;
        }

        if (spotifyLinkBtn && m.spotifyLink) {
            spotifyLinkBtn.href = m.spotifyLink;
        }

        this.loadTrack(0);

        if (this.audioElement) {
            this.audioElement.volume = (m.defaultVolume || 25) / 100;
        }

        if (btnPlay) {
            btnPlay.addEventListener("click", () => this.togglePlayPause());
        }

        if (btnNext) {
            btnNext.addEventListener("click", () => this.playNextTrack());
        }

        if (btnList) {
            btnList.addEventListener("click", (e) => {
                e.stopPropagation();
                this.togglePlaylistPopover();
            });
        }

        if (btnClose) {
            btnClose.addEventListener("click", () => this.closePlaylistPopover());
        }

        document.addEventListener("click", (e) => {
            if (this.isPopoverOpen && !e.target.closest("#playlist-popover") && !e.target.closest("#btn-toggle-list")) {
                this.closePlaylistPopover();
            }
        });

        this.renderTracklist();

        if (m.autoplay) {
            this.playTrack();
            document.body.addEventListener("click", () => {
                if (!this.isPlaying && m.autoplay) {
                    this.playTrack();
                }
            }, { once: true });
        }
    },

    loadTrack(index) {
        const playlist = Config.Music && Config.Music.playlist;
        if (!playlist || playlist.length === 0) return;

        this.currentTrackIndex = (index + playlist.length) % playlist.length;
        const track = playlist[this.currentTrackIndex];

        const titleEl = document.getElementById("player-track-title");
        const artistEl = document.getElementById("player-track-artist");

        if (titleEl) titleEl.textContent = track.title;
        if (artistEl) artistEl.textContent = track.artist;

        if (this.audioElement) {
            this.audioElement.src = track.src;

            this.audioElement.onerror = () => {
                console.warn(`[Luxury Audio] Archivo '${track.src}' no encontrado. Activando sintetizador de respaldo.`);
                this.startFallbackChime();
            };
        }

        this.highlightActiveTrackInList();

        if (this.isPlaying) {
            this.playTrack();
        }
    },

    playTrack() {
        if (!this.audioElement) return;

        const promise = this.audioElement.play();
        if (promise !== undefined) {
            promise.then(() => {
                this.isPlaying = true;
                this.updatePlayPauseUI(true);
            }).catch(() => {
                this.isPlaying = false;
                this.updatePlayPauseUI(false);
            });
        }
    },

    pauseTrack() {
        if (this.audioElement) {
            this.audioElement.pause();
        }
        this.isPlaying = false;
        this.updatePlayPauseUI(false);

        if (this.synthInterval) {
            clearInterval(this.synthInterval);
            this.synthInterval = null;
        }
    },

    togglePlayPause() {
        if (this.isPlaying) {
            this.pauseTrack();
        } else {
            this.playTrack();
        }
    },

    playNextTrack() {
        this.loadTrack(this.currentTrackIndex + 1);
        this.playTrack();
    },

    updatePlayPauseUI(playing) {
        const iconPlay = document.getElementById("icon-play");
        const iconPause = document.getElementById("icon-pause");

        if (iconPlay && iconPause) {
            if (playing) {
                iconPlay.classList.add("hidden");
                iconPause.classList.remove("hidden");
            } else {
                iconPlay.classList.remove("hidden");
                iconPause.classList.add("hidden");
            }
        }
    },

    startFallbackChime() {
        try {
            const AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            if (!this.audioContext) this.audioContext = new AudioCtx();

            const masterGain = this.audioContext.createGain();
            masterGain.gain.setValueAtTime(0.06, this.audioContext.currentTime);
            masterGain.connect(this.audioContext.destination);

            const chords = [220, 261.63, 329.63, 392, 440];
            const playNote = () => {
                if (!this.isPlaying) return;
                const osc = this.audioContext.createOscillator();
                const noteGain = this.audioContext.createGain();

                const freq = chords[Math.floor(Math.random() * chords.length)];
                osc.type = "sine";
                osc.frequency.setValueAtTime(freq, this.audioContext.currentTime);

                noteGain.gain.setValueAtTime(0.001, this.audioContext.currentTime);
                noteGain.gain.exponentialRampToValueAtTime(0.04, this.audioContext.currentTime + 1.2);
                noteGain.gain.exponentialRampToValueAtTime(0.0001, this.audioContext.currentTime + 4.5);

                osc.connect(noteGain);
                noteGain.connect(masterGain);

                osc.start();
                osc.stop(this.audioContext.currentTime + 4.8);
            };

            this.isPlaying = true;
            this.updatePlayPauseUI(true);
            playNote();
            this.synthInterval = setInterval(playNote, 3200);
        } catch (e) {}
    },

    togglePlaylistPopover() {
        const popover = document.getElementById("playlist-popover");
        const btnList = document.getElementById("btn-toggle-list");
        if (!popover) return;

        this.isPopoverOpen = !this.isPopoverOpen;
        if (this.isPopoverOpen) {
            popover.classList.remove("hidden");
            if (btnList) btnList.classList.add("active");
        } else {
            popover.classList.add("hidden");
            if (btnList) btnList.classList.remove("active");
        }
    },

    closePlaylistPopover() {
        const popover = document.getElementById("playlist-popover");
        const btnList = document.getElementById("btn-toggle-list");
        if (popover) popover.classList.add("hidden");
        if (btnList) btnList.classList.remove("active");
        this.isPopoverOpen = false;
    },

    renderTracklist() {
        const container = document.getElementById("popover-tracklist");
        const playlist = Config.Music && Config.Music.playlist;
        if (!container || !playlist) return;

        container.innerHTML = "";
        playlist.forEach((track, index) => {
            const item = document.createElement("div");
            item.className = `tracklist-item ${index === this.currentTrackIndex ? "active-track" : ""}`;
            item.dataset.index = index;
            item.innerHTML = `
                <div class="track-item-left">
                    <span class="track-index">${index + 1}</span>
                    <div class="track-meta">
                        <span class="track-name-row">${track.title}</span>
                        <span class="track-artist-row">${track.artist}</span>
                    </div>
                </div>
                <span class="track-duration">${track.duration || '03:30'}</span>
            `;

            item.addEventListener("click", () => {
                this.loadTrack(index);
                this.playTrack();
            });

            container.appendChild(item);
        });
    },

    highlightActiveTrackInList() {
        const items = document.querySelectorAll(".tracklist-item");
        items.forEach((it, idx) => {
            if (idx === this.currentTrackIndex) {
                it.classList.add("active-track");
            } else {
                it.classList.remove("active-track");
            }
        });
    },

    // ----------------------------------------------------------------
    // 5. ACCIÓN DEL BOTÓN DISCORD
    // ----------------------------------------------------------------
    initDiscordAction() {
        const btn = document.getElementById("btn-discord-copy");
        if (!btn || !Config.Server) return;

        btn.addEventListener("click", () => {
            const dcUrl = Config.Server.discordUrl || "https://discord.gg/luxury-scripts";
            this.copyToClipboard(dcUrl, "Enlace de Discord copiado al portapapeles");
        });
    },

    // ----------------------------------------------------------------
    // 6. CONSEJOS / TIPS ROTATIVOS (SIN EMOJIS)
    // ----------------------------------------------------------------
    initTipsRotator() {
        const tips = Config.Tips;
        if (!tips || !tips.items || tips.items.length === 0) return;

        const tipEl = document.getElementById("origen-tip-rotator");
        if (!tipEl) return;

        tipEl.textContent = tips.items[0];

        setInterval(() => {
            tipEl.style.opacity = "0";
            setTimeout(() => {
                this.currentTipIndex = (this.currentTipIndex + 1) % tips.items.length;
                tipEl.textContent = tips.items[this.currentTipIndex];
                tipEl.style.opacity = "1";
            }, 350);
        }, tips.interval || 4500);
    },

    // ----------------------------------------------------------------
    // 7. CURSOR DE LUJO
    // ----------------------------------------------------------------
    initCustomCursor() {
        if (!Config.Theme || !Config.Theme.enableCustomCursor) return;

        const cursor = document.getElementById("custom-cursor");
        if (!cursor) return;
        cursor.style.display = "block";

        window.addEventListener("mousemove", (e) => {
            cursor.style.left = `${e.clientX}px`;
            cursor.style.top = `${e.clientY}px`;
        });

        document.addEventListener("mouseover", (e) => {
            if (e.target.closest("button, a, .tracklist-item")) {
                cursor.querySelector(".cursor-ring").style.width = "38px";
                cursor.querySelector(".cursor-ring").style.height = "38px";
                cursor.querySelector(".cursor-ring").style.borderColor = "var(--primary-color)";
            } else {
                cursor.querySelector(".cursor-ring").style.width = "28px";
                cursor.querySelector(".cursor-ring").style.height = "28px";
                cursor.querySelector(".cursor-ring").style.borderColor = "var(--border-gold-glow)";
            }
        });
    },

    // ----------------------------------------------------------------
    // 8. BARRA ESTILO ORIGEN: SINCRONIZACIÓN ESTRICTAMENTE MONOTÓNICA
    // ----------------------------------------------------------------
    initProgressLerpLoop() {
        const renderLoop = () => {
            if (this.isCompleted) {
                this.updateOrigenBarUI(100);
                return;
            }

            if (Math.abs(this.targetProgress - this.currentProgress) > 0.05) {
                this.currentProgress += (this.targetProgress - this.currentProgress) * 0.12;
            } else {
                this.currentProgress = this.targetProgress;
            }

            if (this.currentProgress >= 99.8) {
                this.currentProgress = 100;
                this.isCompleted = true;
            }

            this.updateOrigenBarUI(this.currentProgress);
            requestAnimationFrame(renderLoop);
        };
        requestAnimationFrame(renderLoop);
    },

    // Sincronización Monotónica: el progreso NUNCA puede retroceder
    setTargetProgress(percentage) {
        if (this.isCompleted) return;
        const val = Math.max(0, Math.min(100, percentage));
        if (val > this.targetProgress) {
            this.targetProgress = val;
        }
    },

    updateOrigenBarUI(pct) {
        const rounded = Math.round(pct);
        const fillEl = document.getElementById("origen-fill");
        const pctNumberEl = document.getElementById("origen-pct-number");
        const stageBadge = document.getElementById("origen-stage-badge");

        if (fillEl) fillEl.style.width = `${pct}%`;
        if (pctNumberEl) pctNumberEl.textContent = rounded;

        // Fases dinámicas estilo Origen
        if (stageBadge) {
            if (rounded < 25) {
                stageBadge.textContent = "FASE 1 DE 4";
            } else if (rounded < 60) {
                stageBadge.textContent = "FASE 2 DE 4";
            } else if (rounded < 85) {
                stageBadge.textContent = "FASE 3 DE 4";
            } else if (rounded < 100) {
                stageBadge.textContent = "FASE 4 DE 4";
            } else {
                stageBadge.textContent = "¡LISTO!";
                stageBadge.style.background = "rgba(0, 230, 118, 0.2)";
                stageBadge.style.color = "#00e676";
                stageBadge.style.borderColor = "#00e676";
            }
        }

        if (rounded >= 100) {
            this.updateLogMessage("Carga completada. Entrando a la ciudad...");
        }
    },

    updateLogMessage(text) {
        const logEl = document.getElementById("origen-log-message");
        if (logEl && text) {
            logEl.textContent = text;
        }
    },

    // ----------------------------------------------------------------
    // 9. LISTENERS DE EVENTOS FIVEM NATIVOS (NUI)
    // ----------------------------------------------------------------
    initFiveMListener() {
        const handlers = {
            loadProgress: (data) => {
                this.isInFiveM = true;
                const frac = typeof data.loadFraction === "number" ? data.loadFraction : 0;
                this.setTargetProgress(frac * 100);
            },
            onLogLine: (data) => {
                this.isInFiveM = true;
                if (data.message) {
                    this.updateLogMessage(data.message);
                }
            },
            startInitFunction: (data) => {
                this.isInFiveM = true;
                this.updateLogMessage(`Iniciando componente: ${data.functionName || 'sistema'}`);
            },
            startInitFunctionOrder: (data) => {
                this.isInFiveM = true;
                this.updateLogMessage(`Iniciando orden de carga (${data.order || '1'})...`);
            },
            initFunctionInvoking: (data) => {
                this.isInFiveM = true;
                this.updateLogMessage(`Cargando función: ${data.name || 'recurso'}`);
            },
            startDataFileEntries: (data) => {
                this.isInFiveM = true;
                this.updateLogMessage(`Cargando entradas de datos (${data.count || ''})...`);
            },
            performMapLoadFunction: () => {
                this.isInFiveM = true;
                this.updateLogMessage(`Cargando mapa e interiores...`);
            }
        };

        window.addEventListener("message", (event) => {
            const ev = event.data && event.data.eventName;
            if (ev && handlers[ev]) {
                handlers[ev](event.data);
            }
        });
    },

    // ----------------------------------------------------------------
    // 10. NOTIFICACIÓN TOAST
    // ----------------------------------------------------------------
    copyToClipboard(text, customMessage) {
        navigator.clipboard.writeText(text).then(() => {
            this.showToast(customMessage || "Copiado con éxito al portapapeles");
        }).catch(() => {
            const ta = document.createElement("textarea");
            ta.value = text;
            document.body.appendChild(ta);
            ta.select();
            document.execCommand("copy");
            document.body.removeChild(ta);
            this.showToast(customMessage || "Copiado con éxito al portapapeles");
        });
    },

    showToast(message) {
        const toast = document.getElementById("luxury-toast");
        const msgEl = document.getElementById("toast-message");
        if (!toast || !msgEl) return;

        msgEl.textContent = message;
        toast.classList.add("toast-show");

        clearTimeout(this.toastTimer);
        this.toastTimer = setTimeout(() => {
            toast.classList.remove("toast-show");
        }, 2800);
    },

    // ----------------------------------------------------------------
    // 11. MODO SIMULACIÓN PARA NAVEGADOR (NUNCA SE REINICIA)
    // ----------------------------------------------------------------
    detectEnvironment() {
        setTimeout(() => {
            if (!this.isInFiveM && Config.Simulation && Config.Simulation.enabled) {
                this.runBrowserSimulation();
            }
        }, 600);
    },

    runBrowserSimulation() {
        const steps = [
            "Conectando con el servidor FiveM...",
            "Verificando integridad de archivos...",
            "Descargando texturas de alta resolución...",
            "Sincronizando mapeados e interiores de Vinewood...",
            "Cargando vehículos de importación exclusivos...",
            "Inicializando base de datos y scripts de economía...",
            "Sincronizando entidades y ciclo dinámico...",
            "Carga completada. Entrando a Luxury Roleplay."
        ];

        let currentStep = 0;
        let simProgress = 0;
        const totalDuration = Config.Simulation.duration || 9000;
        const intervalTime = 70;
        const increment = 100 / (totalDuration / intervalTime);

        const simTimer = setInterval(() => {
            simProgress += increment;

            if (simProgress >= 100) {
                simProgress = 100;
                this.setTargetProgress(100);
                this.updateLogMessage(steps[steps.length - 1]);
                clearInterval(simTimer); // DETENCIÓN TOTAL: NUNCA se reinicia al 0%
            } else {
                this.setTargetProgress(simProgress);

                const expectedStep = Math.min(
                    steps.length - 1,
                    Math.floor((simProgress / 100) * steps.length)
                );
                if (expectedStep !== currentStep) {
                    currentStep = expectedStep;
                    this.updateLogMessage(steps[currentStep]);
                }
            }
        }, intervalTime);
    }
};
