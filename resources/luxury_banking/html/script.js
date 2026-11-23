/**
 * OKOKBANKING REPLICA - FIVEM EDITION
 * Vanilla JavaScript NUI Controller
 */

(function () {
  'use strict';

  // Estado Local
  let state = {
    name: 'Ciudadano',
    iban: 'OKOK-0000',
    bank: 0,
    cash: 0,
    isAtm: false,
    society: null,
    transactions: [],
    activeAccount: 'personal' // 'personal' o 'society'
  };

  // Referencias DOM Principales
  const appBackdrop = document.getElementById('banking-app');
  const bankWindow = document.getElementById('okok-bank-window');
  const atmWindow = document.getElementById('okok-atm-window');
  const toast = document.getElementById('okok-toast');
  const toastTitle = document.getElementById('toast-title');
  const toastMsg = document.getElementById('toast-message');

  // Header y Toggles
  const txtPlayerName = document.getElementById('txt-player-name');
  const btnTogglePersonal = document.getElementById('btn-toggle-personal');
  const btnToggleSociety = document.getElementById('btn-toggle-society');
  const txtToggleSocietyLabel = document.getElementById('txt-toggle-society-label');
  const btnCloseBank = document.getElementById('btn-close-okok');
  const btnCloseAtm = document.getElementById('btn-close-atm');

  // Tarjeta y Balances
  const creditCard = document.getElementById('credit-card-widget');
  const txtCardNum = document.getElementById('txt-card-num');
  const txtCardHolder = document.getElementById('txt-card-holder');
  const lblBalanceTitle = document.getElementById('lbl-balance-title');
  const txtMainBalance = document.getElementById('txt-main-balance');
  const txtCashAmount = document.getElementById('txt-cash-amount');
  const txtIbanCode = document.getElementById('txt-iban-code');

  // Transacciones
  const transTableList = document.getElementById('trans-table-list');
  const txtTransCount = document.getElementById('txt-trans-count');

  // Botones de Apertura de Modals
  const btnOpenDeposit = document.getElementById('btn-open-deposit-modal');
  const btnOpenWithdraw = document.getElementById('btn-open-withdraw-modal');
  const btnOpenTransfer = document.getElementById('btn-open-transfer-modal');

  // Modals DOM
  const modalDeposit = document.getElementById('modal-deposit');
  const inputDeposit = document.getElementById('input-deposit');
  const btnConfirmDeposit = document.getElementById('btn-confirm-deposit');
  const btnDepAllCash = document.getElementById('btn-dep-all-cash');

  const modalWithdraw = document.getElementById('modal-withdraw');
  const inputWithdraw = document.getElementById('input-withdraw');
  const btnConfirmWithdraw = document.getElementById('btn-confirm-withdraw');
  const btnWithAllBank = document.getElementById('btn-with-all-bank');

  const modalTransfer = document.getElementById('modal-transfer');
  const inputTransferTarget = document.getElementById('input-transfer-target');
  const inputTransferAmount = document.getElementById('input-transfer-amount');
  const inputTransferDesc = document.getElementById('input-transfer-desc');
  const btnConfirmTransfer = document.getElementById('btn-confirm-transfer');

  // Elementos de ATM
  const txtAtmBalance = document.getElementById('txt-atm-balance');
  const inputAtmCustom = document.getElementById('input-atm-custom');
  const btnAtmWithdraw = document.getElementById('btn-atm-withdraw');

  // Formateador de dinero
  function formatMoney(amount) {
    return Number(amount || 0).toLocaleString('en-US');
  }

  // Sonidos Web Audio
  function playTone(freq, type, duration) {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = type || 'sine';
      osc.frequency.setValueAtTime(freq || 440, ctx.currentTime);
      gain.gain.setValueAtTime(0.04, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + (duration || 0.12));
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + (duration || 0.12));
    } catch (e) {}
  }

  // Sistema de Toast Flotante okok
  let toastTimer = null;
  function showToast(title, message, isError = false) {
    if (toastTimer) clearTimeout(toastTimer);
    toastTitle.textContent = title;
    toastMsg.textContent = message;

    if (isError) {
      toast.classList.add('error');
      playTone(220, 'square', 0.2);
    } else {
      toast.classList.remove('error');
      playTone(740, 'sine', 0.15);
    }

    toast.style.display = 'flex';
    toastTimer = setTimeout(() => {
      toast.style.display = 'none';
    }, 3500);
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
      console.log(`[okokBanking Sim] Post NUI -> ${callbackName}:`, data);
      return Promise.resolve();
    }
  }

  // Renderizar la Vista Principal
  function renderView() {
    txtPlayerName.textContent = state.name || 'Ciudadano';
    txtCashAmount.textContent = `$${formatMoney(state.cash)}`;
    txtIbanCode.textContent = state.iban || 'OKOK-0000';

    // Manejo de Sociedad (Boss)
    if (state.society && state.society.balance !== undefined) {
      btnToggleSociety.style.display = 'flex';
      txtToggleSocietyLabel.textContent = state.society.label || state.society.name;
    } else {
      btnToggleSociety.style.display = 'none';
      state.activeAccount = 'personal';
    }

    if (state.activeAccount === 'society' && state.society) {
      // Modo Cuenta Empresarial
      btnTogglePersonal.classList.remove('active');
      btnToggleSociety.classList.add('active');
      creditCard.classList.add('society-theme');

      lblBalanceTitle.textContent = `SALDO DE EMPRESA (${(state.society.label || state.society.name).toUpperCase()})`;
      txtMainBalance.textContent = formatMoney(state.society.balance);
      txtCardHolder.textContent = (state.society.label || state.society.name).toUpperCase();
      txtCardNum.textContent = `CORP •••• •••• ${state.iban.slice(-4)}`;
    } else {
      // Modo Cuenta Personal
      btnTogglePersonal.classList.add('active');
      btnToggleSociety.classList.remove('active');
      creditCard.classList.remove('society-theme');

      lblBalanceTitle.textContent = 'SALDO BANCARIO TOTAL';
      txtMainBalance.textContent = formatMoney(state.bank);
      txtCardHolder.textContent = (state.name || 'Ciudadano').toUpperCase();
      txtCardNum.textContent = `•••• •••• •••• ${state.iban.slice(-4)}`;
    }

    // Renderizar Historial de Transacciones
    renderTransactions(state.transactions || []);
  }

  // Renderizar Tabla de Transacciones estilo okokBanking
  function renderTransactions(transactions) {
    transTableList.innerHTML = '';
    txtTransCount.textContent = `${transactions.length} registros`;

    if (!transactions || transactions.length === 0) {
      transTableList.innerHTML = '<div class="empty-transactions"><p>No hay transacciones recientes en esta cuenta.</p></div>';
      return;
    }

    transactions.forEach(t => {
      const row = document.createElement('div');
      row.className = 'trans-row';

      const isIncome = t.type === 'deposit' || t.type === 'transfer_in';
      const iconClass = isIncome ? 'income' : 'expense';
      const sign = isIncome ? '+' : '-';
      const iconSVG = isIncome
        ? '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><polyline points="19 12 12 19 5 12"></polyline></svg>'
        : '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"></line><polyline points="5 12 12 5 19 12"></polyline></svg>';

      row.innerHTML = `
        <div class="trans-left">
          <div class="trans-icon-circle ${iconClass}">
            ${iconSVG}
          </div>
          <div class="trans-desc-group">
            <span class="trans-title">${t.title || 'Operación Bancaria'}</span>
            <span class="trans-time">${t.date || 'Reciente'}</span>
          </div>
        </div>
        <span class="trans-amount ${iconClass}">${sign}$${formatMoney(t.amount)}</span>
      `;

      transTableList.appendChild(row);
    });
  }

  // Cambiar entre Personal y Sociedad
  btnTogglePersonal.addEventListener('click', () => {
    state.activeAccount = 'personal';
    renderView();
    playTone(550, 'sine', 0.08);
  });

  btnToggleSociety.addEventListener('click', () => {
    state.activeAccount = 'society';
    renderView();
    playTone(550, 'sine', 0.08);
  });

  // ===================================================================
  // MODALS DE ACCIÓN: APERTURA Y CIERRE
  // ===================================================================
  function openModal(modalEl) {
    modalEl.style.display = 'flex';
    playTone(600, 'sine', 0.08);
  }

  function closeModal(modalEl) {
    modalEl.style.display = 'none';
  }

  btnOpenDeposit.addEventListener('click', () => openModal(modalDeposit));
  btnOpenWithdraw.addEventListener('click', () => openModal(modalWithdraw));
  btnOpenTransfer.addEventListener('click', () => openModal(modalTransfer));

  document.querySelectorAll('[data-close]').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-close');
      const targetModal = document.getElementById(targetId);
      if (targetModal) closeModal(targetModal);
    });
  });

  // Chips de selección rápida de monto en Modals
  document.querySelectorAll('.btn-chip[data-target]').forEach(chip => {
    chip.addEventListener('click', () => {
      const targetInput = document.getElementById(chip.getAttribute('data-target'));
      if (targetInput) {
        targetInput.value = chip.getAttribute('data-amount');
        playTone(650, 'sine', 0.05);
      }
    });
  });

  // Botón "TODO" en Depósito
  if (btnDepAllCash) {
    btnDepAllCash.addEventListener('click', () => {
      inputDeposit.value = state.cash;
      playTone(700, 'sine', 0.08);
    });
  }

  // Botón "TODO" en Retiro
  if (btnWithAllBank) {
    btnWithAllBank.addEventListener('click', () => {
      const maxWith = state.activeAccount === 'society' && state.society ? state.society.balance : state.bank;
      inputWithdraw.value = maxWith;
      playTone(700, 'sine', 0.08);
    });
  }

  // ===================================================================
  // ACCIONES BANCARIAS (DEPOSITAR, RETIRAR, TRANSFERIR)
  // ===================================================================

  // Confirmar Depósito
  btnConfirmDeposit.addEventListener('click', () => {
    const amount = parseInt(inputDeposit.value, 10);
    if (isNaN(amount) || amount <= 0) {
      showToast('Error', 'Ingrese un importe válido a depositar.', true);
      return;
    }
    if (amount > state.cash) {
      showToast('Fondos Insuficientes', 'No tienes suficiente efectivo.', true);
      return;
    }

    if (state.activeAccount === 'society') {
      postNUI('societyDeposit', { amount: amount });
    } else {
      postNUI('deposit', { amount: amount });
    }

    inputDeposit.value = '';
    closeModal(modalDeposit);
  });

  // Confirmar Retiro
  btnConfirmWithdraw.addEventListener('click', () => {
    const amount = parseInt(inputWithdraw.value, 10);
    if (isNaN(amount) || amount <= 0) {
      showToast('Error', 'Ingrese un importe válido a retirar.', true);
      return;
    }

    const available = state.activeAccount === 'society' && state.society ? state.society.balance : state.bank;
    if (amount > available) {
      showToast('Fondos Insuficientes', 'Saldo disponible insuficiente.', true);
      return;
    }

    if (state.activeAccount === 'society') {
      postNUI('societyWithdraw', { amount: amount });
    } else {
      postNUI('withdraw', { amount: amount, isAtm: false });
    }

    inputWithdraw.value = '';
    closeModal(modalWithdraw);
  });

  // Confirmar Transferencia
  btnConfirmTransfer.addEventListener('click', () => {
    const target = inputTransferTarget.value.trim();
    const amount = parseInt(inputTransferAmount.value, 10);
    const desc = inputTransferDesc.value.trim();

    if (!target) {
      showToast('Error', 'Especifique el destinatario (ID o IBAN).', true);
      return;
    }
    if (isNaN(amount) || amount <= 0) {
      showToast('Error', 'Ingrese una cantidad válida.', true);
      return;
    }
    if (amount > state.bank) {
      showToast('Fondos Insuficientes', 'Saldo bancario insuficiente.', true);
      return;
    }

    postNUI('transfer', { target: target, amount: amount, description: desc });
    inputTransferTarget.value = '';
    inputTransferAmount.value = '';
    inputTransferDesc.value = '';
    closeModal(modalTransfer);
  });

  // ===================================================================
  // LÓGICA DE CAJERO AUTOMÁTICO (OKOK ATM)
  // ===================================================================
  document.querySelectorAll('.btn-atm-chip').forEach(btn => {
    btn.addEventListener('click', () => {
      const amount = parseInt(btn.getAttribute('data-amount'), 10);
      postNUI('withdraw', { amount: amount, isAtm: true });
      playTone(800, 'sine', 0.1);
    });
  });

  btnAtmWithdraw.addEventListener('click', () => {
    const amount = parseInt(inputAtmCustom.value, 10);
    if (isNaN(amount) || amount <= 0) {
      showToast('Error', 'Ingrese un importe válido para el cajero.', true);
      return;
    }
    postNUI('withdraw', { amount: amount, isAtm: true });
    inputAtmCustom.value = '';
  });

  // ===================================================================
  // CIERRE DE NUI
  // ===================================================================
  function closeBanking() {
    appBackdrop.style.display = 'none';
    modalDeposit.style.display = 'none';
    modalWithdraw.style.display = 'none';
    modalTransfer.style.display = 'none';
    postNUI('close');
  }

  btnCloseBank.addEventListener('click', closeBanking);
  btnCloseAtm.addEventListener('click', closeBanking);

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (modalDeposit.style.display === 'flex') {
        closeModal(modalDeposit);
      } else if (modalWithdraw.style.display === 'flex') {
        closeModal(modalWithdraw);
      } else if (modalTransfer.style.display === 'flex') {
        closeModal(modalTransfer);
      } else {
        closeBanking();
      }
    }
  });

  // ===================================================================
  // RECEPCIÓN DE MENSAJES NUI DESDE EL CLIENTE
  // ===================================================================
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'OPEN_BANK') {
      state = Object.assign(state, data.payload || {});
      appBackdrop.style.display = 'flex';

      if (state.isAtm) {
        bankWindow.style.display = 'none';
        atmWindow.style.display = 'flex';
        txtAtmBalance.textContent = formatMoney(state.bank);
      } else {
        atmWindow.style.display = 'none';
        bankWindow.style.display = 'flex';
        renderView();
      }
    } else if (data.action === 'UPDATE_DATA') {
      state = Object.assign(state, data.payload || {});
      if (state.isAtm) {
        txtAtmBalance.textContent = formatMoney(state.bank);
      } else {
        renderView();
      }
    } else if (data.action === 'CLOSE_BANK') {
      appBackdrop.style.display = 'none';
    } else if (data.action === 'NOTIFICATION') {
      showToast(data.title || 'Notificación', data.message || '', data.isError || false);
    }
  });

  // Pruebas directas en Navegador Web
  if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    const testBar = document.getElementById('browser-test-bar');
    if (testBar) testBar.style.display = 'flex';

    const mockData = {
      name: 'Alexander Vance',
      iban: 'OKOK-9214',
      bank: 348500,
      cash: 6200,
      isAtm: false,
      society: {
        name: 'police',
        label: 'Los Santos Police Dept',
        balance: 1845000
      },
      transactions: [
        { type: 'deposit', amount: 15000, title: 'Nómina Policial LSPD', date: 'Hoy, 18:30' },
        { type: 'transfer_in', amount: 50000, title: 'Transferencia de Marcus Vance', date: 'Ayer, 21:15' },
        { type: 'withdraw', amount: 3500, title: 'Retiro en Cajero Fleeca', date: '20 Nov, 14:00' }
      ]
    };

    document.getElementById('btn-test-personal').addEventListener('click', () => {
      mockData.isAtm = false;
      state.activeAccount = 'personal';
      window.postMessage({ action: 'OPEN_BANK', payload: mockData }, '*');
    });

    document.getElementById('btn-test-society').addEventListener('click', () => {
      mockData.isAtm = false;
      state.activeAccount = 'society';
      window.postMessage({ action: 'OPEN_BANK', payload: mockData }, '*');
    });

    document.getElementById('btn-test-atm').addEventListener('click', () => {
      mockData.isAtm = true;
      window.postMessage({ action: 'OPEN_BANK', payload: mockData }, '*');
    });

    // Auto-abrir en navegador
    setTimeout(() => {
      window.postMessage({ action: 'OPEN_BANK', payload: mockData }, '*');
    }, 250);
  }

})();
