/**
 * LUXURY GARAGE - OKOKGARAGE STYLE
 * Vanilla JavaScript NUI Controller
 */

(function () {
  'use strict';

  let currentData = {
    garageId: 'LegionSquare',
    garageLabel: 'Garaje Central',
    isImpound: false,
    fee: 1500,
    vehicles: []
  };

  let activeFilter = 'all';

  // Referencias DOM
  const backdrop = document.getElementById('garage-backdrop');
  const txtTitle = document.getElementById('txt-garage-title');
  const txtSubtitle = document.getElementById('txt-garage-subtitle');
  const btnClose = document.getElementById('btn-close-garage');
  const inputSearch = document.getElementById('input-search-vehicle');
  const vehicleGrid = document.getElementById('vehicle-grid');
  const feeBadge = document.getElementById('impound-fee-badge');
  const txtImpoundCost = document.getElementById('txt-impound-cost');

  const countAll = document.getElementById('count-all');
  const countStored = document.getElementById('count-stored');
  const countOut = document.getElementById('count-out');
  const filterBtns = document.querySelectorAll('.btn-filter');

  // Sonidos Web Audio
  function playTone(freq, type, duration) {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type || 'sine';
      osc.frequency.setValueAtTime(freq || 500, ctx.currentTime);
      gain.gain.setValueAtTime(0.04, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + (duration || 0.12));
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + (duration || 0.12));
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
      console.log(`[Garage Sim] Post NUI -> ${callbackName}:`, data);
      return Promise.resolve();
    }
  }

  // Renderizar la Lista de Vehículos
  function renderVehicles() {
    vehicleGrid.innerHTML = '';

    const query = inputSearch.value.trim().toLowerCase();
    const list = currentData.vehicles || [];

    // Calcular contadores
    let storedNum = 0;
    let outNum = 0;

    list.forEach(v => {
      if (v.state === 1) storedNum++;
      else outNum++;
    });

    countAll.textContent = list.length;
    countStored.textContent = storedNum;
    countOut.textContent = outNum;

    // Filtrar según pestaña y búsqueda
    const filtered = list.filter(v => {
      const matchesFilter =
        activeFilter === 'all' ||
        (activeFilter === 'stored' && v.state === 1) ||
        (activeFilter === 'out' && v.state !== 1);

      const matchesQuery =
        !query ||
        (v.model && v.model.toLowerCase().includes(query)) ||
        (v.plate && v.plate.toLowerCase().includes(query));

      return matchesFilter && matchesQuery;
    });

    if (filtered.length === 0) {
      vehicleGrid.innerHTML = '<div class="empty-garage"><p>No se encontraron vehículos en este garaje.</p></div>';
      return;
    }

    filtered.forEach(v => {
      const card = document.createElement('div');
      card.className = 'veh-card';

      const isStored = v.state === 1;
      const statusText = isStored ? 'En Garaje' : (currentData.isImpound ? 'En Depósito' : 'En Calle');
      const statusClass = isStored ? 'in-garage' : 'out-impound';

      const engineVal = Math.min(100, Math.max(0, v.engine || 100));
      const bodyVal = Math.min(100, Math.max(0, v.body || 100));
      const fuelVal = Math.min(100, Math.max(0, v.fuel || 100));

      const actionBtnHtml = currentData.isImpound
        ? `<button class="btn-veh-action btn-impound-veh" data-plate="${v.plate}">Pagar Rescate ($${currentData.fee})</button>`
        : (isStored
            ? `<button class="btn-veh-action btn-spawn-veh" data-plate="${v.plate}">Sacar Vehículo</button>`
            : `<button class="btn-veh-action" style="background: rgba(255,255,255,0.05); color: #8c92a4; cursor: not-allowed;" disabled>Fuera del Garaje</button>`
          );

      card.innerHTML = `
        <div class="veh-card-header">
          <div class="veh-meta-left">
            <div class="veh-icon-box">
              <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="2" y="7" width="20" height="13" rx="2"></rect>
                <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
              </svg>
            </div>
            <div class="veh-title-group">
              <span class="veh-model-name">${(v.model || 'Vehículo').toUpperCase()}</span>
              <span class="veh-plate-pill">[ ${v.plate} ]</span>
            </div>
          </div>
          <span class="veh-status-badge ${statusClass}">${statusText}</span>
        </div>

        <div class="veh-stats-meters">
          <div class="meter-item">
            <div class="meter-label-row">
              <span>Motor</span>
              <span>${engineVal}%</span>
            </div>
            <div class="meter-bar-track">
              <div class="meter-bar-fill fill-engine" style="width: ${engineVal}%;"></div>
            </div>
          </div>

          <div class="meter-item">
            <div class="meter-label-row">
              <span>Chasis</span>
              <span>${bodyVal}%</span>
            </div>
            <div class="meter-bar-track">
              <div class="meter-bar-fill fill-body" style="width: ${bodyVal}%;"></div>
            </div>
          </div>

          <div class="meter-item">
            <div class="meter-label-row">
              <span>Gasolina</span>
              <span>${fuelVal}%</span>
            </div>
            <div class="meter-bar-track">
              <div class="meter-bar-fill fill-fuel" style="width: ${fuelVal}%;"></div>
            </div>
          </div>
        </div>

        ${actionBtnHtml}
      `;

      // Event listener del botón
      const btnAction = card.querySelector('.btn-veh-action:not([disabled])');
      if (btnAction) {
        btnAction.addEventListener('click', () => {
          playTone(680, 'sine', 0.1);
          if (currentData.isImpound) {
            postNUI('payImpound', { plate: v.plate });
          } else {
            postNUI('spawnVehicle', { plate: v.plate });
          }
        });
      }

      vehicleGrid.appendChild(card);
    });
  }

  // Filtrado por Pestañas
  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeFilter = btn.getAttribute('data-filter');
      renderVehicles();
      playTone(500, 'sine', 0.05);
    });
  });

  // Búsqueda en vivo
  inputSearch.addEventListener('input', () => {
    renderVehicles();
  });

  // Cerrar Garaje
  function closeGarage() {
    backdrop.style.display = 'none';
    postNUI('close');
  }

  btnClose.addEventListener('click', closeGarage);

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeGarage();
    }
  });

  // Escuchar NUI Messages
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'OPEN_GARAGE') {
      currentData = Object.assign(currentData, data.payload || {});
      txtTitle.textContent = (currentData.garageLabel || 'GARAJE').toUpperCase();
      txtSubtitle.textContent = currentData.isImpound ? 'DEPÓSITO DE VEHÍCULOS INCAUTADOS' : 'VEHÍCULOS EN PROPIEDAD';

      if (currentData.isImpound) {
        feeBadge.style.display = 'flex';
        txtImpoundCost.textContent = `$${Number(currentData.fee || 1500).toLocaleString('en-US')}`;
      } else {
        feeBadge.style.display = 'none';
      }

      backdrop.style.display = 'flex';
      inputSearch.value = '';
      activeFilter = 'all';
      filterBtns.forEach(b => b.classList.toggle('active', b.getAttribute('data-filter') === 'all'));
      renderVehicles();
    } else if (data.action === 'CLOSE_GARAGE') {
      backdrop.style.display = 'none';
    }
  });

  // Pruebas en Navegador
  if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    const testBar = document.getElementById('browser-test-bar');
    if (testBar) testBar.style.display = 'flex';

    const mockVehicles = [
      { plate: 'LUX 8891', model: 'sultanrs', garage: 'LegionSquare', state: 1, engine: 98, body: 100, fuel: 85 },
      { plate: 'VRTX 442', model: 'elegy', garage: 'LegionSquare', state: 1, engine: 92, body: 95, fuel: 60 },
      { plate: 'SPD 1001', model: 't20', garage: 'LegionSquare', state: 0, engine: 70, body: 80, fuel: 40 }
    ];

    document.getElementById('btn-test-garage').addEventListener('click', () => {
      window.postMessage({
        action: 'OPEN_GARAGE',
        payload: {
          garageId: 'LegionSquare',
          garageLabel: 'Garaje Central Legion Square',
          isImpound: false,
          fee: 0,
          vehicles: mockVehicles
        }
      }, '*');
    });

    document.getElementById('btn-test-impound').addEventListener('click', () => {
      window.postMessage({
        action: 'OPEN_GARAGE',
        payload: {
          garageId: 'CityImpound',
          garageLabel: 'Depósito Municipal de Los Santos',
          isImpound: true,
          fee: 1500,
          vehicles: mockVehicles
        }
      }, '*');
    });

    // Auto-apertura de prueba
    setTimeout(() => {
      document.getElementById('btn-test-garage').click();
    }, 250);
  }

})();
