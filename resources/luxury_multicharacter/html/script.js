/**
 * ====================================================================
 * LUXURY ESX MULTICHARACTER - SIMPLE, CLEAN & FAST
 * Lógica Frontend Vanilla JS + FiveM CEF Compatibility
 * ====================================================================
 */

(function () {
  'use strict';

  // Detección de entorno (Navegador estándar vs FiveM CEF)
  const isBrowser = !window.invokeNative && !window.GetParentResourceName;

  // Audio simple
  const AudioEngine = {
    ctx: null,

    init() {
      if (!this.ctx) {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) this.ctx = new AudioCtx();
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
    },

    playTick() {
      try {
        this.init();
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(1200, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, this.ctx.currentTime + 0.03);
        gain.gain.setValueAtTime(0.04, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.03);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.03);
      } catch (e) {}
    },

    playSuccess() {
      try {
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        [523.25, 659.25, 783.99].forEach((freq, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now + idx * 0.06);
          gain.gain.setValueAtTime(0.05, now + idx * 0.06);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.06 + 0.35);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now + idx * 0.06);
          osc.stop(now + idx * 0.06 + 0.35);
        });
      } catch (e) {}
    }
  };

  // Estado del Multipersonaje
  let characters = [
    {
      citizenid: 'LX-88921',
      firstname: 'Alexander',
      lastname: 'Vance',
      birthdate: '1998-05-15',
      gender: 0,
      nationality: 'Los Santos',
      phone: '555-8821',
      job: 'LSPD',
      bank: 450000,
      cash: 12500
    },
    {
      citizenid: 'LX-34190',
      firstname: 'Marcus',
      lastname: 'Sterling',
      birthdate: '1994-11-20',
      gender: 0,
      nationality: 'Liberty City',
      phone: '555-1192',
      job: 'Empresario',
      bank: 1200000,
      cash: 45000
    }
  ];

  let maxSlots = 4;
  let selectedChar = null;
  let charToDelete = null;
  let notifyTimer = null;

  // Comunicación con FiveM o Emulación en Navegador
  const fetchNui = async (eventName, data = {}) => {
    if (isBrowser) {
      console.log(`%c[ESX MULTICHAR]%c Event: "${eventName}"`, 'color: #d4af37; font-weight: bold;', 'color: #fff;', data);
      return { status: 'ok' };
    }
    try {
      const resource = window.GetParentResourceName ? window.GetParentResourceName() : 'luxury_multicharacter';
      const response = await fetch(`https://${resource}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
      });
      return await response.json();
    } catch (e) {
      return { status: 'error' };
    }
  };

  // Mostrar Notificación Flotante
  function showNotify(type, message) {
    const box = document.getElementById('mc-notification');
    const msg = document.getElementById('mc-alert-msg');
    const icon = document.getElementById('mc-alert-icon');
    if (!box || !msg) return;

    if (notifyTimer) clearTimeout(notifyTimer);

    box.className = `esx-toast alert-${type}`;
    if (icon) {
      icon.innerHTML = type === 'success'
        ? '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"/></svg>'
        : '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>';
    }
    msg.textContent = message;
    box.style.display = 'flex';

    notifyTimer = setTimeout(() => {
      box.style.display = 'none';
    }, 4000);
  }

  // Formato monetario
  function formatMoney(amount) {
    return '$' + Number(amount || 0).toLocaleString('en-US');
  }

  // ==================================================================
  // RENDERIZADO DE RANURAS (ESTILO ESX SIMPLE)
  // ==================================================================
  function renderSlots() {
    const container = document.getElementById('slots-list');
    if (!container) return;

    container.innerHTML = '';

    for (let i = 0; i < maxSlots; i++) {
      const char = characters[i];
      const isSelected = selectedChar && char && selectedChar.citizenid === char.citizenid;

      if (char) {
        const card = document.createElement('div');
        card.className = `slot-card ${isSelected ? 'active' : ''}`;

        let detailsHtml = '';
        let actionsHtml = '';

        if (isSelected) {
          const genderText = Number(char.gender) === 1 ? 'Femenino' : 'Masculino';
          detailsHtml = `
            <div class="slot-details-table">
              <div class="detail-line">
                <span class="detail-label">Trabajo:</span>
                <span class="detail-value text-cyan">${char.job || 'Desempleado'}</span>
              </div>
              <div class="detail-line">
                <span class="detail-label">Banco:</span>
                <span class="detail-value text-gold mono">${formatMoney(char.bank)}</span>
              </div>
              <div class="detail-line">
                <span class="detail-label">Efectivo:</span>
                <span class="detail-value text-emerald mono">${formatMoney(char.cash)}</span>
              </div>
              <div class="detail-line">
                <span class="detail-label">Nacimiento:</span>
                <span class="detail-value">${char.birthdate || '1998-05-15'}</span>
              </div>
              <div class="detail-line">
                <span class="detail-label">Sexo:</span>
                <span class="detail-value">${genderText}</span>
              </div>
            </div>
          `;

          actionsHtml = `
            <div class="slot-actions-row">
              <button class="btn-slot-play" id="btn-play-action">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                <span>JUGAR</span>
              </button>
              <button class="btn-slot-delete" id="btn-del-action" title="Eliminar personaje">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
              </button>
            </div>
          `;
        }

        card.innerHTML = `
          <div class="slot-head">
            <span class="slot-num-badge">RANURA #${i + 1}</span>
            <span class="slot-cid-badge">${char.citizenid}</span>
          </div>
          <div class="slot-name">${char.firstname} ${char.lastname}</div>
          ${detailsHtml}
          ${actionsHtml}
        `;

        card.onclick = (e) => {
          // Si el clic fue en un botón de acción, no re-seleccionar
          if (e.target.closest('#btn-play-action')) {
            playCharacter(char);
            return;
          }
          if (e.target.closest('#btn-del-action')) {
            openDeleteModal(char);
            return;
          }
          selectCharacter(char);
        };

        container.appendChild(card);
      } else {
        // Ranura Vacía
        const emptyCard = document.createElement('div');
        emptyCard.className = 'slot-card empty';
        emptyCard.innerHTML = `
          <div class="empty-plus-circle">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          </div>
          <span class="empty-title">+ Crear Personaje</span>
          <span class="empty-sub">Ranura #${i + 1} disponible</span>
        `;
        emptyCard.onclick = () => openCreateModal();
        container.appendChild(emptyCard);
      }
    }
  }

  // Seleccionar Personaje
  function selectCharacter(char) {
    selectedChar = char;
    AudioEngine.playTick();
    renderSlots();
  }

  // Jugar / Iniciar Sesión con Personaje
  function playCharacter(char) {
    AudioEngine.playSuccess();
    if (isBrowser) {
      showNotify('success', `Iniciando juego con ${char.firstname} ${char.lastname}...`);
    } else {
      fetchNui('selectCharacter', { citizenid: char.citizenid });
    }
  }

  // Abrir Modal de Creación
  function openCreateModal() {
    AudioEngine.playTick();
    const modal = document.getElementById('modal-create-char');
    if (modal) modal.style.display = 'flex';
    const firstInput = document.getElementById('inp-create-fname');
    if (firstInput) firstInput.focus();
  }

  function closeCreateModal() {
    const modal = document.getElementById('modal-create-char');
    if (modal) modal.style.display = 'none';
  }

  // Abrir Modal de Eliminación
  function openDeleteModal(char) {
    charToDelete = char;
    const modal = document.getElementById('modal-delete-char');
    const nameEl = document.getElementById('txt-del-name');
    const inp = document.getElementById('inp-delete-keyword');
    if (nameEl) nameEl.textContent = `${char.firstname} ${char.lastname}`;
    if (inp) inp.value = '';
    if (modal) modal.style.display = 'flex';
    if (inp) inp.focus();
  }

  function closeDeleteModal() {
    charToDelete = null;
    const modal = document.getElementById('modal-delete-char');
    if (modal) modal.style.display = 'none';
  }

  // Apertura y Cierre General NUI
  function openMultichar(payload) {
    if (payload) {
      characters = payload.characters || [];
      maxSlots = payload.maxSlots || 4;
    }

    const container = document.getElementById('multichar-container');
    if (container) container.style.display = 'flex';

    if (characters.length > 0) {
      selectCharacter(characters[0]);
    } else {
      renderSlots();
      openCreateModal();
    }
  }

  function closeMultichar() {
    const container = document.getElementById('multichar-container');
    if (container) container.style.display = 'none';
    closeCreateModal();
    closeDeleteModal();
  }

  // ==================================================================
  // EVENT LISTENERS DOM
  // ==================================================================
  function setupEvents() {
    // Modal Creación: Cancelar
    const btnCancelCreate = document.getElementById('btn-cancel-create');
    if (btnCancelCreate) {
      btnCancelCreate.addEventListener('click', closeCreateModal);
    }

    // Modal Creación: Submit Formulario
    const formCreate = document.getElementById('form-create-char');
    if (formCreate) {
      formCreate.addEventListener('submit', (e) => {
        e.preventDefault();

        const fname = document.getElementById('inp-create-fname').value.trim();
        const lname = document.getElementById('inp-create-lname').value.trim();
        const bdate = document.getElementById('inp-create-birthdate').value;
        const hgt = Number(document.getElementById('inp-create-height').value) || 180;
        const gender = Number(document.getElementById('inp-create-gender').value);
        const nation = document.getElementById('inp-create-nationality').value.trim() || 'Los Santos';

        if (!fname || !lname) {
          showNotify('error', 'Ingresa nombre y apellido válidos.');
          return;
        }

        const newChar = {
          citizenid: `LX-${Math.floor(10000 + Math.random() * 90000)}`,
          firstname: fname,
          lastname: lname,
          birthdate: bdate,
          gender: gender,
          height: hgt,
          nationality: nation,
          phone: `555-${Math.floor(1000 + Math.random() * 9000)}`,
          job: 'Desempleado',
          bank: 5000,
          cash: 500
        };

        if (isBrowser) {
          characters.push(newChar);
          showNotify('success', `Personaje "${fname} ${lname}" creado con éxito.`);
          closeCreateModal();
          selectCharacter(newChar);
        } else {
          fetchNui('createCharacter', newChar);
          closeCreateModal();
        }

        formCreate.reset();
      });
    }

    // Modal Borrado: Cancelar
    const btnCancelDel = document.getElementById('btn-cancel-del');
    if (btnCancelDel) {
      btnCancelDel.addEventListener('click', closeDeleteModal);
    }

    // Modal Borrado: Confirmar
    const btnConfirmDel = document.getElementById('btn-confirm-del');
    if (btnConfirmDel) {
      btnConfirmDel.addEventListener('click', () => {
        const inp = document.getElementById('inp-delete-keyword');
        const val = (inp.value || '').trim().toUpperCase();

        if (val !== 'BORRAR') {
          showNotify('error', 'Debes escribir exactamente "BORRAR" para confirmar.');
          return;
        }

        if (!charToDelete) return;

        if (isBrowser) {
          const name = `${charToDelete.firstname} ${charToDelete.lastname}`;
          characters = characters.filter((c) => c.citizenid !== charToDelete.citizenid);
          showNotify('success', `Personaje "${name}" eliminado.`);
          closeDeleteModal();
          if (characters.length > 0) {
            selectCharacter(characters[0]);
          } else {
            selectedChar = null;
            renderSlots();
          }
        } else {
          fetchNui('deleteCharacter', { citizenid: charToDelete.citizenid });
          closeDeleteModal();
        }
      });
    }

    // Pruebas en Navegador
    if (isBrowser) {
      const browserBar = document.getElementById('mc-browser-bar');
      if (browserBar) browserBar.style.display = 'flex';

      const reopenBtn = document.getElementById('btn-reopen-mc');
      if (reopenBtn) reopenBtn.addEventListener('click', () => openMultichar());

      const addBtn = document.getElementById('btn-add-sample-char');
      if (addBtn) {
        addBtn.addEventListener('click', () => {
          if (characters.length >= maxSlots) {
            showNotify('error', `Límite máximo alcanzado (${maxSlots}).`);
            return;
          }
          const names = ['Mateo', 'Valentina', 'Carlos', 'Camila', 'Santiago'];
          const lasts = ['Herrera', 'Mendoza', 'Morales', 'Paredes', 'Silva'];
          const rf = names[Math.floor(Math.random() * names.length)];
          const rl = lasts[Math.floor(Math.random() * lasts.length)];
          const dummy = {
            citizenid: `LX-${Math.floor(10000 + Math.random() * 90000)}`,
            firstname: rf,
            lastname: rl,
            birthdate: '1999-04-10',
            gender: Math.random() > 0.5 ? 1 : 0,
            nationality: 'Los Santos',
            phone: `555-${Math.floor(1000 + Math.random() * 9000)}`,
            job: 'Mecánico',
            bank: 35000,
            cash: 2100
          };
          characters.push(dummy);
          showNotify('success', `Personaje de prueba agregado: ${rf} ${rl}`);
          selectCharacter(dummy);
        });
      }

      openMultichar();
    }
  }

  // Inicialización
  document.addEventListener('DOMContentLoaded', setupEvents);
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setupEvents();
  }

  // Escuchadores FiveM NUI
  window.addEventListener('message', (event) => {
    const { action, payload } = event.data || {};
    if (action === 'OPEN_MULTICHAR') {
      openMultichar(payload);
    } else if (action === 'CLOSE_MULTICHAR') {
      closeMultichar();
    } else if (action === 'SHOW_NOTIFICATION') {
      showNotify(payload.type, payload.message);
    }
  });

})();
