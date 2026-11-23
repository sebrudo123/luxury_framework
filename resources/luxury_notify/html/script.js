/**
 * LUXURY NOTIFY & TEXTUI - JAVASCRIPT CONTROLLER
 */

(function () {
  'use strict';

  const notifyContainer = document.getElementById('notify-container');
  const textUIContainer = document.getElementById('textui-container');
  const textUIMsg = document.getElementById('textui-msg');

  // Sonidos Web Audio
  function playAudioTone(freq, type, duration) {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type || 'sine';
      osc.frequency.setValueAtTime(freq || 500, ctx.currentTime);
      gain.gain.setValueAtTime(0.04, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + (duration || 0.15));
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + (duration || 0.15));
    } catch (e) {}
  }

  // Iconos SVG limpios por tipo de notificación
  const icons = {
    success: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>',
    error: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>',
    info: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>',
    warning: '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>'
  };

  // Sonidos por tipo
  const soundProfiles = {
    success: () => playAudioTone(780, 'sine', 0.15),
    error: () => playAudioTone(240, 'square', 0.2),
    info: () => playAudioTone(580, 'sine', 0.12),
    warning: () => playAudioTone(440, 'triangle', 0.18)
  };

  // Crear y mostrar notificación
  function createNotification(data) {
    const type = data.type || 'info';
    const duration = data.duration || 4000;
    const title = data.title || 'Aviso';
    const message = data.message || '';

    const card = document.createElement('div');
    card.className = `notify-card ${type}`;

    const iconSvg = icons[type] || icons.info;

    card.innerHTML = `
      <div class="notify-body">
        <div class="notify-icon-circle">
          ${iconSvg}
        </div>
        <div class="notify-text-group">
          <span class="notify-title">${title}</span>
          <span class="notify-message">${message}</span>
        </div>
      </div>
      <div class="notify-progress" style="animation-duration: ${duration}ms;"></div>
    `;

    notifyContainer.appendChild(card);
    if (soundProfiles[type]) soundProfiles[type]();

    setTimeout(() => {
      card.classList.add('hide');
      setTimeout(() => {
        if (card.parentNode) card.parentNode.removeChild(card);
      }, 250);
    }, duration);
  }

  // Mostrar TextUI
  function showTextUI(payload) {
    let rawText = payload.text || '';
    // Reemplazar corchetes estilo [E] por elementos <kbd>E</kbd>
    rawText = rawText.replace(/\[([A-Za-z0-9\s~]+)\]/g, '<kbd>$1</kbd>');
    textUIMsg.innerHTML = rawText;
    textUIContainer.style.display = 'flex';
  }

  // Ocultar TextUI
  function hideTextUI() {
    textUIContainer.style.display = 'none';
  }

  // Escuchar NUI Messages
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'NOTIFY') {
      createNotification(data.payload || {});
    } else if (data.action === 'SHOW_TEXTUI') {
      showTextUI(data.payload || {});
    } else if (data.action === 'HIDE_TEXTUI') {
      hideTextUI();
    }
  });

  // Pruebas en Navegador
  if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    const bar = document.getElementById('browser-test-bar');
    if (bar) bar.style.display = 'flex';

    document.getElementById('btn-test-success').addEventListener('click', () => {
      createNotification({ type: 'success', title: 'Operación Exitosa', message: 'Vehículo guardado en el garaje correctamente.', duration: 4000 });
    });
    document.getElementById('btn-test-error').addEventListener('click', () => {
      createNotification({ type: 'error', title: 'Error', message: 'No dispones de fondos suficientes para pagar la multa.', duration: 4000 });
    });
    document.getElementById('btn-test-info').addEventListener('click', () => {
      createNotification({ type: 'info', title: 'Información', message: 'Has cerrado con llave tu vehículo.', duration: 4000 });
    });
    document.getElementById('btn-test-warning').addEventListener('click', () => {
      createNotification({ type: 'warning', title: 'Atención', message: 'El motor del vehículo presenta daños graves.', duration: 4000 });
    });
    document.getElementById('btn-test-textui').addEventListener('click', () => {
      if (textUIContainer.style.display === 'flex') {
        hideTextUI();
      } else {
        showTextUI({ text: 'Presiona [E] para acceder a tu Garaje' });
      }
    });

    // Auto-notificación de prueba
    setTimeout(() => {
      createNotification({ type: 'success', title: 'Luxury Notify Listo', message: 'Sistema de notificaciones cargado correctamente.', duration: 4000 });
    }, 300);
  }

})();
