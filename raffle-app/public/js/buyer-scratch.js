/**
 * buyer-scratch.js — Buyer scratch card interaction logic
 *
 * Used by buyer-scratch-card.html.  Expects the following globals
 * provided by the hosting page before this script runs:
 *   window.SCRATCH_TICKET_ID   — numeric DB id of the buyer_scratch_tickets row
 *   window.SCRATCH_BUYER_PHONE — buyer's phone number (used to verify ownership)
 *   window.SCRATCH_TICKET_TYPE — e.g. 'basic', 'gold', …
 *   window.SCRATCH_IS_SCRATCHED — boolean (true if already revealed)
 *   window.SCRATCH_PRIZE_EMOJI  — stored emoji (only set when already scratched)
 *   window.SCRATCH_PRIZE_TEXT   — stored text  (only set when already scratched)
 *   window.SCRATCH_PRIZE_VALUE  — stored value (only set when already scratched)
 *   window.SCRATCH_HAS_PRIZE    — stored has_prize (only set when already scratched)
 */

(function () {
  'use strict';

  // ── Ticket colour map ─────────────────────────────────────────────────
  const TICKET_COLORS = {
    basic:   '#10b981',
    premium: '#7c3aed',
    bronze:  '#ea580c',
    silver:  '#94a3b8',
    gold:    '#f59e0b',
    diamond: '#06b6d4'
  };

  // ── Auto-reveal threshold (55 %) ──────────────────────────────────────
  const REVEAL_THRESHOLD = 55;
  const BRUSH_SIZE = 18;

  // ── DOM refs ──────────────────────────────────────────────────────────
  const canvas        = document.getElementById('scratch-canvas');
  const progressFill  = document.getElementById('scratch-progress-fill');
  const progressLabel = document.getElementById('scratch-progress-label');
  const prizeBanner   = document.getElementById('prize-banner');
  const scratchHint   = document.getElementById('scratch-hint');

  if (!canvas) return; // Not on scratch card page

  const ctx = canvas.getContext('2d');
  let isDrawing = false;
  let revealed   = false;
  let apiCalled  = false;

  // ── Resize canvas to its CSS display size ────────────────────────────
  function resizeCanvas() {
    const rect = canvas.getBoundingClientRect();
    canvas.width  = rect.width;
    canvas.height = rect.height;
    if (!revealed) drawCover();
  }

  // ── Draw grey cover layer ─────────────────────────────────────────────
  function drawCover() {
    const w = canvas.width;
    const h = canvas.height;
    const color = TICKET_COLORS[window.SCRATCH_TICKET_TYPE] || '#808080';

    ctx.fillStyle = color;
    ctx.fillRect(0, 0, w, h);

    // Light sparkle texture
    ctx.globalAlpha = 0.25;
    for (let i = 0; i < 80; i++) {
      ctx.fillStyle = 'rgba(255,255,255,0.7)';
      ctx.beginPath();
      ctx.arc(Math.random() * w, Math.random() * h, Math.random() * 2.5, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    // Instruction text
    ctx.fillStyle = 'rgba(255,255,255,0.9)';
    ctx.font = 'bold 22px Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('GRATE ISIT LA ✨', w / 2, h / 2 - 14);
    ctx.font = 'bold 13px Arial, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.fillText('Scratch here to reveal your prize', w / 2, h / 2 + 18);
  }

  // ── Scratch a circle at (x, y) canvas coords ─────────────────────────
  function scratchAt(x, y) {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(x, y, BRUSH_SIZE, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
    updateProgress();
  }

  // ── Compute % of transparent pixels ──────────────────────────────────
  function updateProgress() {
    const data   = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    let transparent = 0;
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] < 128) transparent++;
    }
    const pct = Math.round((transparent / (data.length / 4)) * 100);

    if (progressFill)  progressFill.style.width  = pct + '%';
    if (progressLabel) progressLabel.textContent = pct + '% grate';

    if (!revealed && pct >= REVEAL_THRESHOLD) {
      revealAll();
    }
  }

  // ── Reveal everything (clear canvas) and call API ────────────────────
  function revealAll() {
    if (revealed) return;
    revealed = true;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    if (progressFill)  progressFill.style.width = '100%';
    if (progressLabel) progressLabel.textContent = '100% grate';
    if (scratchHint) scratchHint.style.display = 'none';
    callScratchApi();
  }

  // ── POST to backend to get the prize ─────────────────────────────────
  async function callScratchApi() {
    if (apiCalled) return;
    apiCalled = true;

    try {
      const resp = await fetch(
        `/api/public/buyer-scratch-ticket/${window.SCRATCH_TICKET_ID}/scratch`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone: window.SCRATCH_BUYER_PHONE })
        }
      );

      if (!resp.ok) {
        const err = await resp.json().catch(() => ({}));
        showError(err.error || 'Could not retrieve prize. Please refresh.');
        return;
      }

      const data = await resp.json();
      showPrize(data.prize_emoji, data.prize_text, data.prize_value, data.has_prize);
    } catch (e) {
      showError('Network error. Please check your connection and refresh.');
    }
  }

  // ── Display prize result ──────────────────────────────────────────────
  function showPrize(emoji, text, value, hasPrize) {
    const emojiEl = document.getElementById('prize-reveal-emoji');
    const textEl  = document.getElementById('prize-reveal-text');
    if (emojiEl) emojiEl.textContent = emoji || '😅';
    if (textEl)  textEl.textContent  = text  || 'ESEYE ANKÒ';

    if (!prizeBanner) return;
    prizeBanner.classList.remove('win', 'lose');
    const bannerTitle = prizeBanner.querySelector('h3');
    const bannerText  = prizeBanner.querySelector('p');

    if (hasPrize && value > 0) {
      prizeBanner.classList.add('win');
      if (bannerTitle) bannerTitle.textContent = '🎉 Ou Genyen!';
      if (bannerText)  bannerText.textContent  = `Kontakte nou pou reklame ${value.toLocaleString()} GOUD ou a.`;
    } else {
      prizeBanner.classList.add('lose');
      if (bannerTitle) bannerTitle.textContent = '😅 Eseye Ankò!';
      if (bannerText)  bannerText.textContent  = 'Pa gen chans fwa sa a. Achte yon lòt tikè!';
    }
  }

  function showError(msg) {
    const el = document.getElementById('scratch-error-msg');
    if (el) { el.textContent = msg; el.style.display = 'block'; }
  }

  // ── Pointer helpers ───────────────────────────────────────────────────
  function canvasCoords(e) {
    const rect   = canvas.getBoundingClientRect();
    const scaleX = canvas.width  / rect.width;
    const scaleY = canvas.height / rect.height;
    const clientX = e.clientX !== undefined ? e.clientX : e.touches[0].clientX;
    const clientY = e.clientY !== undefined ? e.clientY : e.touches[0].clientY;
    return {
      x: (clientX - rect.left) * scaleX,
      y: (clientY - rect.top)  * scaleY
    };
  }

  // ── Mouse events ──────────────────────────────────────────────────────
  canvas.addEventListener('mousedown', (e) => { if (revealed) return; isDrawing = true; const p = canvasCoords(e); scratchAt(p.x, p.y); });
  canvas.addEventListener('mousemove', (e) => { if (!isDrawing || revealed) return; const p = canvasCoords(e); scratchAt(p.x, p.y); });
  canvas.addEventListener('mouseup',   () => { isDrawing = false; });
  canvas.addEventListener('mouseleave',() => { isDrawing = false; });

  // ── Touch events ──────────────────────────────────────────────────────
  canvas.addEventListener('touchstart', (e) => { e.preventDefault(); if (revealed) return; isDrawing = true; const p = canvasCoords(e); scratchAt(p.x, p.y); }, { passive: false });
  canvas.addEventListener('touchmove',  (e) => { e.preventDefault(); if (!isDrawing || revealed) return; const p = canvasCoords(e); scratchAt(p.x, p.y); }, { passive: false });
  canvas.addEventListener('touchend',   (e) => { e.preventDefault(); isDrawing = false; },                                                                   { passive: false });

  // ── "Reveal all" button ───────────────────────────────────────────────
  const revealBtn = document.getElementById('btn-reveal-all');
  if (revealBtn) revealBtn.addEventListener('click', revealAll);

  // ── Init ──────────────────────────────────────────────────────────────
  function init() {
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    // If ticket was already scratched, show stored prize immediately
    if (window.SCRATCH_IS_SCRATCHED) {
      revealed   = true;
      apiCalled  = true;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      if (progressFill)  progressFill.style.width = '100%';
      if (progressLabel) progressLabel.textContent = '100% grate';
      if (scratchHint) scratchHint.style.display = 'none';
      showPrize(
        window.SCRATCH_PRIZE_EMOJI,
        window.SCRATCH_PRIZE_TEXT,
        window.SCRATCH_PRIZE_VALUE,
        window.SCRATCH_HAS_PRIZE
      );
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}());
