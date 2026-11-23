/**
 * luxury_hud: Lógica Frontend Idéntica a Origen HUD
 * Dial circular de tacómetro/velocímetro + Vitals compactos de 32px
 * 100% interactivo en FiveM CEF y en Navegadores Web Normales
 */

(function () {
  'use strict';

  const isBrowser = !window.invokeNative && !window.GetParentResourceName;
  const VITALS_CIRCUMFERENCE = 78.5; // Para círculos compactos r=12.5
  const DIAL_CIRCUMFERENCE = 339.3;  // Para el dial principal r=54
  const MINI_CIRCUMFERENCE = 88.0;   // Para los mini medidores r=14

  // Estado del HUD
  let state = {
    visible: true,
    cinematic: false,
    settings: {
      dynamic: false,
      compass: true,
      scale: 100
    },
    status: {
      health: 100,
      armor: 75,
      hunger: 85,
      thirst: 90,
      stamina: 100,
      stress: 0,
      oxygen: 100,
      isUnderwater: false,
      voice: { range: 2, talking: false, radio: false },
      location: {
        street: 'ALTA STREET',
        zone: 'HAWICK',
        heading: 0,
        cardinal: 'N',
        time: '14:32'
      }
    },
    vehicle: {
      inVehicle: false,
      speed: 0,
      speedUnit: 'kmh',
      rpm: 0,
      gear: '1',
      fuel: 100,
      engine: 100,
      seatbelt: false,
      lights: 0,
      locked: false
    }
  };

  // Cargar ajustes guardados de LocalStorage
  try {
    const saved = localStorage.getItem('origen_hud_settings');
    if (saved) {
      state.settings = Object.assign(state.settings, JSON.parse(saved));
    }
  } catch (e) {}

  // Actualizar círculo de progreso SVG genérico
  function setCircleProgress(elementId, percent, circumference) {
    const el = document.getElementById(elementId);
    if (!el) return;
    const clamped = Math.max(0, Math.min(100, percent));
    const offset = circumference - (clamped / 100) * circumference;
    el.style.strokeDashoffset = offset;
  }

  // Renderizar Vitals Circulares Ultra-Compactos (32px)
  function updateVitalsUI() {
    const s = state.status;
    const dyn = state.settings.dynamic;

    // Salud
    setCircleProgress('ring-health', s.health, VITALS_CIRCUMFERENCE);
    const healthEl = document.getElementById('vital-health');
    healthEl.style.display = (dyn && s.health >= 100) ? 'none' : 'flex';

    // Blindaje / Chaleco
    setCircleProgress('ring-armor', s.armor, VITALS_CIRCUMFERENCE);
    const armorEl = document.getElementById('vital-armor');
    armorEl.style.display = s.armor > 0 ? 'flex' : 'none';

    // Hambre
    setCircleProgress('ring-hunger', s.hunger, VITALS_CIRCUMFERENCE);
    const hungerEl = document.getElementById('vital-hunger');
    hungerEl.style.display = (dyn && s.hunger >= 100) ? 'none' : 'flex';

    // Sed
    setCircleProgress('ring-thirst', s.thirst, VITALS_CIRCUMFERENCE);
    const thirstEl = document.getElementById('vital-thirst');
    thirstEl.style.display = (dyn && s.thirst >= 100) ? 'none' : 'flex';

    // Resistencia
    setCircleProgress('ring-stamina', s.stamina, VITALS_CIRCUMFERENCE);
    const staminaEl = document.getElementById('vital-stamina');
    staminaEl.style.display = (s.stamina < 100 || isBrowser) ? 'flex' : 'none';

    // Estrés
    setCircleProgress('ring-stress', s.stress, VITALS_CIRCUMFERENCE);
    const stressEl = document.getElementById('vital-stress');
    stressEl.style.display = (s.stress > 0 || isBrowser) ? 'flex' : 'none';

    // Oxígeno
    const oxygenEl = document.getElementById('vital-oxygen');
    if (s.isUnderwater || isBrowser) {
      oxygenEl.style.display = 'flex';
      setCircleProgress('ring-oxygen', s.oxygen, VITALS_CIRCUMFERENCE);
    } else {
      oxygenEl.style.display = 'none';
    }

    // Voz y Micrófono
    const voiceEl = document.getElementById('vital-voice');
    voiceEl.classList.toggle('talking', !!s.voice.talking);

    const range = s.voice.range || 2;
    const voicePercent = range === 1 ? 33 : (range === 2 ? 66 : 100);
    setCircleProgress('ring-voice', voicePercent, VITALS_CIRCUMFERENCE);

    document.getElementById('vdot-1').className = `vdot ${range >= 1 ? 'on' : ''}`;
    document.getElementById('vdot-2').className = `vdot ${range >= 2 ? 'on' : ''}`;
    document.getElementById('vdot-3').className = `vdot ${range >= 3 ? 'on' : ''}`;

    // Brújula y Calle
    const loc = s.location || {};
    const streetBar = document.getElementById('origen-street-bar');
    if (state.settings.compass && !state.cinematic) {
      streetBar.style.display = 'flex';
      document.getElementById('txt-cardinal').textContent = loc.cardinal || 'N';
      document.getElementById('txt-heading').textContent = `${loc.heading || 0}°`;
      document.getElementById('txt-street-name').textContent = loc.street || 'LOS SANTOS';
      document.getElementById('txt-zone-name').textContent = loc.zone || '';
      document.getElementById('txt-game-time').textContent = loc.time || '12:00';
    } else {
      streetBar.style.display = 'none';
    }
  }

  // Renderizar Velocímetro Idéntico a Origen HUD
  function updateVehicleUI() {
    const v = state.vehicle;
    const carHud = document.getElementById('origen-speedo-panel');

    if (!v.inVehicle || state.cinematic) {
      carHud.style.display = 'none';
      return;
    }

    carHud.style.display = 'flex';

    // Velocidad y Marcha
    document.getElementById('txt-speed').textContent = Math.floor(v.speed);
    document.getElementById('txt-unit').textContent = (v.speedUnit || 'kmh').toUpperCase();
    document.getElementById('txt-gear').textContent = v.gear;

    // Dial Circular de RPM / Tacómetro
    const rpmPercent = Math.max(0, Math.min(1.0, v.rpm || 0)) * 100;
    setCircleProgress('dial-rpm-fill', rpmPercent, DIAL_CIRCUMFERENCE);

    // Mini Medidor de Gasolina
    document.getElementById('txt-fuel').textContent = `${v.fuel}%`;
    setCircleProgress('mini-fuel-fill', v.fuel, MINI_CIRCUMFERENCE);

    // Mini Medidor de Motor
    document.getElementById('txt-engine').textContent = `${v.engine}%`;
    setCircleProgress('mini-engine-fill', v.engine, MINI_CIRCUMFERENCE);

    // Cinturón de Seguridad
    const indSb = document.getElementById('ind-seatbelt');
    if (v.seatbelt) {
      indSb.className = 'status-icon-pill seatbelt-on';
    } else {
      indSb.className = 'status-icon-pill seatbelt-off';
    }

    // Luces
    const indLights = document.getElementById('ind-lights');
    if (v.lights === 2) {
      indLights.className = 'status-icon-pill lights-high';
    } else if (v.lights === 1) {
      indLights.className = 'status-icon-pill lights-low';
    } else {
      indLights.className = 'status-icon-pill lights-off';
    }

    // Bloqueo de Puertas
    const indLock = document.getElementById('ind-lock');
    indLock.className = `status-icon-pill ${v.locked ? 'lock-closed' : 'lock-open'}`;
  }

  // Alternar Cinemática (Bandas Negras 21:9)
  function setCinematic(active) {
    state.cinematic = active;
    document.getElementById('cinema-top').classList.toggle('active', active);
    document.getElementById('cinema-bottom').classList.toggle('active', active);

    document.getElementById('vitals-cluster').style.display = active ? 'none' : 'flex';
    document.getElementById('origen-street-bar').style.display = active ? 'none' : 'flex';

    if (active) {
      document.getElementById('origen-speedo-panel').style.display = 'none';
    } else {
      updateVehicleUI();
    }
  }

  // Menú de Ajustes /hud
  function openSettings() {
    const modal = document.getElementById('settings-modal');
    modal.style.display = 'flex';

    document.getElementById('chk-dynamic').checked = state.settings.dynamic;
    document.getElementById('chk-compass').checked = state.settings.compass;
    document.getElementById('chk-cinematic').checked = state.cinematic;
    document.getElementById('rng-scale').value = state.settings.scale || 100;
    document.getElementById('txt-scale-val').textContent = `${state.settings.scale || 100}%`;
  }

  function closeSettings() {
    document.getElementById('settings-modal').style.display = 'none';
    if (!isBrowser) {
      const resource = window.GetParentResourceName ? window.GetParentResourceName() : 'luxury_hud';
      fetch(`https://${resource}/closeSettings`, { method: 'POST' });
    }
  }

  function saveSettings() {
    state.settings.dynamic = document.getElementById('chk-dynamic').checked;
    state.settings.compass = document.getElementById('chk-compass').checked;
    const isCine = document.getElementById('chk-cinematic').checked;
    state.settings.scale = Number(document.getElementById('rng-scale').value);

    // Aplicar escala general
    document.getElementById('hud-root').style.transform = `scale(${state.settings.scale / 100})`;
    document.getElementById('hud-root').style.transformOrigin = 'bottom left';

    setCinematic(isCine);
    try {
      localStorage.setItem('origen_hud_settings', JSON.stringify(state.settings));
    } catch (e) {}

    closeSettings();
    updateVitalsUI();
    updateMoneyUI({ cash: 4500, bank: 82500, black: 0 });
    updateVehicleUI();
  }

  // Inicialización
  document.addEventListener('DOMContentLoaded', () => {
    updateVitalsUI();
    updateVehicleUI();

    // Controles de Ajustes
    document.getElementById('btn-close-settings').onclick = closeSettings;
    document.getElementById('btn-save-settings').onclick = saveSettings;
    document.getElementById('rng-scale').oninput = (e) => {
      document.getElementById('txt-scale-val').textContent = `${e.target.value}%`;
    };

    // Modo Pruebas en Navegador
    if (isBrowser) {
      document.getElementById('browser-toolbar').style.display = 'flex';

      // Activar vehículo de prueba por defecto
      state.vehicle.inVehicle = true;
      state.vehicle.speed = 112;
      state.vehicle.gear = '4';
      state.vehicle.rpm = 0.65;
      state.vehicle.fuel = 84;
      state.vehicle.engine = 98;
      state.vehicle.lights = 1;
      updateVehicleUI();

      // Botones de pruebas
      document.getElementById('btn-dev-veh').onclick = () => {
        state.vehicle.inVehicle = !state.vehicle.inVehicle;
        updateVehicleUI();
      };

      document.getElementById('btn-dev-accel').onclick = () => {
        state.vehicle.speed = Math.min(320, state.vehicle.speed + 35);
        state.vehicle.rpm = Math.min(1.0, state.vehicle.rpm + 0.16);
        state.vehicle.gear = `${Math.min(6, Math.floor(state.vehicle.speed / 45) + 1)}`;
        updateVehicleUI();
      };

      document.getElementById('btn-dev-brake').onclick = () => {
        state.vehicle.speed = Math.max(0, state.vehicle.speed - 35);
        state.vehicle.rpm = Math.max(0.1, state.vehicle.rpm - 0.16);
        state.vehicle.gear = state.vehicle.speed === 0 ? 'N' : `${Math.max(1, Math.floor(state.vehicle.speed / 45) + 1)}`;
        updateVehicleUI();
      };

      document.getElementById('btn-dev-seatbelt').onclick = () => {
        state.vehicle.seatbelt = !state.vehicle.seatbelt;
        updateVehicleUI();
      };

      document.getElementById('btn-dev-talk').onclick = () => {
        state.status.voice.talking = !state.status.voice.talking;
        updateVitalsUI();
      };

      document.getElementById('btn-dev-damage').onclick = () => {
        state.status.health = Math.max(0, state.status.health - 25);
        updateVitalsUI();
      };

      document.getElementById('btn-dev-menu').onclick = openSettings;

      // Tecla B para el cinturón en navegador
      window.addEventListener('keydown', (e) => {
        if (e.key === 'b' || e.key === 'B') {
          state.vehicle.seatbelt = !state.vehicle.seatbelt;
          updateVehicleUI();
        }
      });
    }
  });

  // Escuchadores FiveM NUI
  
  function updateMoneyUI(data) {
    if (!data) return;
    const txtCash = document.getElementById('txt-hud-cash');
    const txtBank = document.getElementById('txt-hud-bank');
    const txtBlack = document.getElementById('txt-hud-black');
    const pillBlack = document.getElementById('money-black-pill');

    if (txtCash && data.cash !== undefined) {
      txtCash.textContent = Number(data.cash).toLocaleString('en-US');
    }
    if (txtBank && data.bank !== undefined) {
      txtBank.textContent = Number(data.bank).toLocaleString('en-US');
    }
    if (txtBlack && pillBlack && data.black !== undefined) {
      txtBlack.textContent = Number(data.black).toLocaleString('en-US');
      pillBlack.style.display = Number(data.black) > 0 ? 'flex' : 'none';
    }
  }

  window.addEventListener('message', (event) => {
    const { action, payload } = event.data || {};
    if (action === 'UPDATE_MONEY') {
      updateMoneyUI(payload);
    } else if (action === 'UPDATE_STATUS') {
      Object.assign(state.status, payload);
      updateVitalsUI();
    } else if (action === 'UPDATE_VEHICLE') {
      Object.assign(state.vehicle, payload);
      updateVehicleUI();
    } else if (action === 'UPDATE_SEATBELT') {
      state.vehicle.seatbelt = payload.active;
      updateVehicleUI();
    } else if (action === 'TOGGLE_CINEMATIC') {
      setCinematic(payload.active);
    } else if (action === 'OPEN_SETTINGS') {
      openSettings();
    } else if (action === 'SET_VISIBLE') {
      state.visible = payload.visible;
      document.getElementById('hud-root').style.display = payload.visible ? 'block' : 'none';
    }
  });

  // Tecla ESC para cerrar modal de ajustes
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && document.getElementById('settings-modal').style.display === 'flex') {
      closeSettings();
    }
  });
})();
