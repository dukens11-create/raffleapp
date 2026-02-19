/**
 * buyer-scratch.js
 * Shared scratch-card interaction logic for buyer scratch pages.
 */

const TICKET_EMOJIS = {
  basic: '🎉',
  premium: '🎰',
  bronze: '🏆',
  silver: '💫',
  gold: '👑',
  diamond: '💎'
};

const TICKET_LABELS = {
  basic: 'Basic',
  premium: 'Premium',
  bronze: 'Bronze',
  silver: 'Silver',
  gold: 'Gold',
  diamond: 'Diamond'
};

/**
 * BuyerScratchCard - handles canvas scratch interaction for a single ticket.
 *
 * @param {object} options
 * @param {string}  options.canvasId        - id of <canvas> element
 * @param {string}  options.prizeDisplayId  - id of element showing prize content underneath
 * @param {string}  options.hintId          - id of scratch hint element
 * @param {number}  options.ticketId        - database id of buyer_scratch_tickets row
 * @param {string}  options.phone           - buyer phone for ownership verification
 * @param {number}  [options.brushSize=18]  - brush radius in px
 * @param {number}  [options.threshold=55]  - auto-reveal percentage (0-100)
 * @param {Function} [options.onReveal]     - callback called with prize data after reveal
 */
class BuyerScratchCard {
  constructor(options) {
    this.canvasId = options.canvasId;
    this.prizeDisplayId = options.prizeDisplayId;
    this.hintId = options.hintId;
    this.ticketId = options.ticketId;
    this.phone = options.phone;
    this.brushSize = options.brushSize || 18;
    this.threshold = options.threshold || 55;
    this.onReveal = options.onReveal || null;

    this.canvas = document.getElementById(this.canvasId);
    this.ctx = this.canvas ? this.canvas.getContext('2d') : null;
    this.isDrawing = false;
    this.scratched = 0;
    this.revealed = false;

    if (this.canvas) {
      this._setupCanvas();
      this._attachEvents();
    }
  }

  _setupCanvas() {
    const wrapper = this.canvas.parentElement;
    const rect = wrapper.getBoundingClientRect();
    const w = wrapper.clientWidth || 340;
    const h = wrapper.clientHeight || 220;

    this.canvas.width = w;
    this.canvas.height = h;

    // Fill grey overlay
    this.ctx.fillStyle = '#808080';
    this.ctx.fillRect(0, 0, w, h);

    // Scratch prompt text
    this.ctx.fillStyle = 'rgba(255,255,255,0.55)';
    this.ctx.font = `bold ${Math.round(w * 0.045)}px sans-serif`;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText('✦ GRATE ICI ✦', w / 2, h / 2);

    this.ctx.globalCompositeOperation = 'destination-out';
  }

  _getPos(e) {
    const rect = this.canvas.getBoundingClientRect();
    const scaleX = this.canvas.width / rect.width;
    const scaleY = this.canvas.height / rect.height;
    if (e.touches && e.touches.length > 0) {
      return {
        x: (e.touches[0].clientX - rect.left) * scaleX,
        y: (e.touches[0].clientY - rect.top) * scaleY
      };
    }
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY
    };
  }

  _scratch(pos) {
    this.ctx.beginPath();
    this.ctx.arc(pos.x, pos.y, this.brushSize, 0, Math.PI * 2);
    this.ctx.fill();
    this._checkProgress();
  }

  _checkProgress() {
    if (this.revealed) return;
    const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
    const pixels = imageData.data;
    let transparent = 0;
    for (let i = 3; i < pixels.length; i += 4) {
      if (pixels[i] < 128) transparent++;
    }
    const total = pixels.length / 4;
    this.scratched = (transparent / total) * 100;

    if (this.scratched >= this.threshold) {
      this._reveal();
    }
  }

  _reveal() {
    if (this.revealed) return;
    this.revealed = true;

    // Clear the entire canvas
    this.ctx.globalCompositeOperation = 'destination-out';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Hide canvas and hint
    this.canvas.style.display = 'none';
    const hint = document.getElementById(this.hintId);
    if (hint) hint.classList.add('hidden');

    // Call server to mark as scratched and get the prize
    this._callRevealAPI();
  }

  async _callRevealAPI() {
    try {
      const response = await fetch(`/api/buyer/scratch-ticket/${this.ticketId}/scratch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: this.phone })
      });
      const data = await response.json();
      if (response.ok && data.success) {
        if (this.onReveal) this.onReveal(data);
        this._showPrizeInDisplay(data);
      } else {
        console.error('Scratch API error:', data.error);
      }
    } catch (err) {
      console.error('Network error during scratch reveal:', err);
    }
  }

  _showPrizeInDisplay(prize) {
    const display = document.getElementById(this.prizeDisplayId);
    if (!display) return;

    const emojiEl = display.querySelector('.prize-emoji-large');
    const textEl = display.querySelector('.prize-text-main');

    if (emojiEl) emojiEl.textContent = prize.prize_emoji || '😅';
    if (textEl) {
      textEl.textContent = prize.prize_text || 'ESEYE ANKÒ';
      textEl.className = 'prize-text-main ' + (prize.has_prize ? 'winner' : 'no-prize');
    }
  }

  _attachEvents() {
    const canvas = this.canvas;

    // Mouse events
    canvas.addEventListener('mousedown', (e) => {
      this.isDrawing = true;
      this._scratch(this._getPos(e));
    });
    canvas.addEventListener('mousemove', (e) => {
      if (!this.isDrawing) return;
      this._scratch(this._getPos(e));
    });
    canvas.addEventListener('mouseup', () => { this.isDrawing = false; });
    canvas.addEventListener('mouseleave', () => { this.isDrawing = false; });

    // Touch events
    canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      this.isDrawing = true;
      this._scratch(this._getPos(e));
    }, { passive: false });
    canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      if (!this.isDrawing) return;
      this._scratch(this._getPos(e));
    }, { passive: false });
    canvas.addEventListener('touchend', () => { this.isDrawing = false; });
  }
}

// ─── Utility helpers used by both list and card pages ───────────────────────

function normalizePhone(phone) {
  return phone.replace(/\D/g, '');
}

function getStoredPhone() {
  return localStorage.getItem('buyer_scratch_phone') || '';
}

function storePhone(phone) {
  localStorage.setItem('buyer_scratch_phone', phone);
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('fr-HT', { year: 'numeric', month: 'short', day: 'numeric' });
}
