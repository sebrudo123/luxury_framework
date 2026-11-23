/**
 * LUXURY RADIAL MENU - JAVASCRIPT CONTROLLER
 */

(function () {
  'use strict';

  let currentItems = [];
  let menuStack = []; // Pila para navegación en submenús
  let activeHoverItem = null;

  // Referencias DOM
  const backdrop = document.getElementById('radial-backdrop');
  const itemsRing = document.getElementById('radial-items-ring');
  const centerHub = document.getElementById('radial-center-hub');
  const hubIcon = document.getElementById('hub-icon-wrap');
  const hubLabel = document.getElementById('hub-label');
  const hubSub = document.getElementById('hub-sub');

  // Mapa de Iconos SVG Vectoriales (Cero Emojis)
  const svgIcons = {
    engine: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10h2v4H4zM20 10h2v4h-2zM6 8h12v8H6zM10 5v3M14 5v3M10 16v3M14 16v3"/></svg>',
    doors: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="7" cy="12" r="1"/></svg>',
    window: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="12" y1="3" x2="12" y2="21"/></svg>',
    seat: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 18v3M20 18v3M6 18h12v-5a4 4 0 0 0-4-4H6z"/><path d="M6 9V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v5"/></svg>',
    id: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><line x1="15" y1="8" x2="17" y2="8"/><line x1="15" y1="12" x2="17" y2="12"/><line x1="7" y1="16" x2="17" y2="16"/></svg>',
    key: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="7.5" cy="15.5" r="4.5"/><path d="m21 3-9.5 9.5M15.5 7.5l3 3M18 5l3 3"/></svg>',
    shirt: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/></svg>',
    mask: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12c2-4 6-6 10-6s8 2 10 6c-2 4-6 6-10 6s-8-2-10-6z"/><circle cx="8" cy="12" r="2"/><circle cx="16" cy="12" r="2"/></svg>',
    hat: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 18h20M5 18V9a7 7 0 0 1 14 0v9"/></svg>',
    glasses: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="14" r="4"/><circle cx="18" cy="14" r="4"/><line x1="10" y1="14" x2="14" y2="14"/><path d="M2 14l3-6M22 14l-3-6"/></svg>',
    vest: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4v16h16V4l-5 3-3-3-3 3z"/></svg>',
    user: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="7" r="4"/><path d="M5.5 21a6.5 6.5 0 0 1 13 0"/></svg>',
    back: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>'
  };

  // Sonidos Web Audio
  function playTone(freq, duration) {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq || 500, ctx.currentTime);
      gain.gain.setValueAtTime(0.03, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + (duration || 0.08));
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + (duration || 0.08));
    } catch (e) {}
  }

  // Enviar a NUI Callback
  function postNUI(callbackName, data) {
    if (window.invokeNative) {
      return fetch(`https://${GetParentResourceName()}/${callbackName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
      }).catch(() => {});
    } else {
      console.log(`[Radial Sim] Post NUI -> ${callbackName}:`, data);
      return Promise.resolve();
    }
  }

  // Posicionar matemáticamente los nodos en el anillo circular
  function renderRadialRing(items) {
    itemsRing.innerHTML = '';
    const total = items.length;
    if (total === 0) return;

    const radius = 155; // Radio en píxeles desde el centro
    const centerOffset = 220; // 440 / 2

    // Ángulo inicial (arriba: -90 grados o -PI/2)
    const angleStep = (2 * Math.PI) / total;

    items.forEach((item, index) => {
      const angle = index * angleStep - Math.PI / 2;
      const x = centerOffset + radius * Math.cos(angle);
      const y = centerOffset + radius * Math.sin(angle);

      const node = document.createElement('div');
      node.className = 'radial-node';
      node.style.left = `${x}px`;
      node.style.top = `${y}px`;

      const iconMarkup = svgIcons[item.icon] || svgIcons.user;

      node.innerHTML = `
        <div class="node-icon">${iconMarkup}</div>
        <span class="node-label">${item.label}</span>
      `;

      // Hover
      node.addEventListener('mouseenter', () => {
        playTone(600, 0.05);
        activeHoverItem = item;
        hubLabel.textContent = item.label;
        hubSub.textContent = item.items ? 'Abrir Submenú' : 'Ejecutar Acción';
        hubIcon.innerHTML = iconMarkup;
      });

      // Clic para ejecutar o entrar en submenú
      node.addEventListener('click', () => {
        playTone(750, 0.09);
        if (item.items && item.items.length > 0) {
          // Guardar estado en la pila y navegar al submenú
          menuStack.push({ items: currentItems, label: hubLabel.textContent });
          currentItems = item.items;
          renderRadialRing(currentItems);
          updateHubForSubmenu(item.label);
        } else if (item.action) {
          // Ejecutar acción
          postNUI('executeAction', { action: item.action });
          closeRadial();
        }
      });

      itemsRing.appendChild(node);
    });
  }

  function updateHubForSubmenu(parentLabel) {
    hubLabel.textContent = parentLabel || 'SUBMENÚ';
    hubSub.textContent = 'Clic aquí para Volver';
    hubIcon.innerHTML = svgIcons.back;
  }

  // Clic en el Hub Central
  centerHub.addEventListener('click', () => {
    if (menuStack.length > 0) {
      // Volver al nivel anterior
      const previous = menuStack.pop();
      currentItems = previous.items;
      renderRadialRing(currentItems);
      hubLabel.textContent = previous.label || 'SELECCIONAR';
      hubSub.textContent = 'Menú Rápido';
      hubIcon.innerHTML = svgIcons.user;
      playTone(480, 0.08);
    } else {
      closeRadial();
    }
  });

  // Cerrar Menú
  function closeRadial() {
    backdrop.style.display = 'none';
    menuStack = [];
    postNUI('close');
  }

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'F1') {
      closeRadial();
    }
  });

  // Escuchar NUI Messages
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'OPEN_RADIAL') {
      currentItems = data.payload.items || [];
      menuStack = [];
      backdrop.style.display = 'flex';
      hubLabel.textContent = data.payload.inVehicle ? 'VEHÍCULO' : 'CIUDADANO';
      hubSub.textContent = 'Menú Rápido';
      hubIcon.innerHTML = data.payload.inVehicle ? svgIcons.engine : svgIcons.user;
      renderRadialRing(currentItems);
    } else if (data.action === 'CLOSE_RADIAL') {
      backdrop.style.display = 'none';
    }
  });

  // Pruebas en Navegador
  if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    const bar = document.getElementById('browser-test-bar');
    if (bar) bar.style.display = 'flex';

    const testVehItems = [
      { id: 'veh_engine', label: 'Motor', icon: 'engine', action: 'toggle_engine' },
      { id: 'veh_doors', label: 'Puertas', icon: 'doors', items: [
        { id: 'door_hood', label: 'Capó', icon: 'doors', action: 'door_hood' },
        { id: 'door_trunk', label: 'Maletero', icon: 'doors', action: 'door_trunk' },
        { id: 'door_fl', label: 'Delantera Izq', icon: 'doors', action: 'door_fl' },
        { id: 'door_fr', label: 'Delantera Der', icon: 'doors', action: 'door_fr' }
      ]},
      { id: 'veh_windows', label: 'Ventanillas', icon: 'window', action: 'toggle_windows' },
      { id: 'veh_seats', label: 'Asientos', icon: 'seat', items: [
        { id: 'seat_driver', label: 'Conductor', icon: 'seat', action: 'seat_driver' },
        { id: 'seat_passenger', label: 'Copiloto', icon: 'seat', action: 'seat_passenger' }
      ]}
    ];

    const testFootItems = [
      { id: 'citizen_id', label: 'DNI', icon: 'id', action: 'show_id' },
      { id: 'vehicle_keys', label: 'Dar Llaves', icon: 'key', action: 'give_keys' },
      { id: 'clothes_menu', label: 'Ropa', icon: 'shirt', items: [
        { id: 'cloth_mask', label: 'Máscara', icon: 'mask', action: 'toggle_mask' },
        { id: 'cloth_hat', label: 'Sombrero', icon: 'hat', action: 'toggle_hat' },
        { id: 'cloth_glasses', label: 'Gafas', icon: 'glasses', action: 'toggle_glasses' },
        { id: 'cloth_vest', label: 'Chaleco', icon: 'vest', action: 'toggle_vest' }
      ]},
      { id: 'emotes_quick', label: 'Animaciones', icon: 'user', items: [
        { id: 'emote_crossarms', label: 'Cruzar Brazos', icon: 'user', action: 'emote_crossarms' },
        { id: 'emote_sit', label: 'Sentarse', icon: 'user', action: 'emote_sit' }
      ]}
    ];

    document.getElementById('btn-test-veh').addEventListener('click', () => {
      window.postMessage({ action: 'OPEN_RADIAL', payload: { inVehicle: true, items: testVehItems } }, '*');
    });

    document.getElementById('btn-test-foot').addEventListener('click', () => {
      window.postMessage({ action: 'OPEN_RADIAL', payload: { inVehicle: false, items: testFootItems } }, '*');
    });

    // Auto-apertura de prueba
    setTimeout(() => {
      document.getElementById('btn-test-veh').click();
    }, 250);
  }

})();
