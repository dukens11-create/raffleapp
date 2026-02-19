/**
 * ScratchCard - Interactive canvas-based scratch-off card
 * Supports mouse (desktop) and touch (mobile) events.
 */
class ScratchCard {
  constructor(canvasId, prizeData) {
    this.canvas = document.getElementById(canvasId);
    this.ctx = this.canvas.getContext('2d');
    this.prizeData = prizeData;
    this.isScratching = false;
    this.revealed = false;
    this.brushSize = 40;

    this.init();
  }

  init() {
    this.setupCanvas();
    this.drawOverlay();
    this.attachEventListeners();
  }

  setupCanvas() {
    const container = this.canvas.parentElement;
    this.canvas.width = container.offsetWidth;
    this.canvas.height = container.offsetHeight;
    this.totalPixels = this.canvas.width * this.canvas.height;
  }

  drawOverlay() {
    this.ctx.fillStyle = '#808080';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw "SCRATCH HERE" text
    this.ctx.fillStyle = '#909090';
    this.ctx.font = 'bold 24px Arial';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText('✦ GRATE ICI ✦', this.canvas.width / 2, this.canvas.height / 2);
    this.ctx.font = '16px Arial';
    this.ctx.fillText('SCRATCH HERE', this.canvas.width / 2, this.canvas.height / 2 + 36);
  }

  attachEventListeners() {
    // Mouse events (desktop)
    this.canvas.addEventListener('mousedown', (e) => this.startScratching(e));
    this.canvas.addEventListener('mousemove', (e) => this.scratch(e));
    this.canvas.addEventListener('mouseup', () => this.stopScratching());
    this.canvas.addEventListener('mouseleave', () => this.stopScratching());

    // Touch events (mobile)
    this.canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      this.startScratching(e.touches[0]);
    }, { passive: false });

    this.canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      this.scratch(e.touches[0]);
    }, { passive: false });

    this.canvas.addEventListener('touchend', (e) => {
      e.preventDefault();
      this.stopScratching();
    }, { passive: false });
  }

  startScratching(e) {
    this.isScratching = true;
    this.scratch(e);
  }

  scratch(e) {
    if (!this.isScratching) return;

    const rect = this.canvas.getBoundingClientRect();
    const scaleX = this.canvas.width / rect.width;
    const scaleY = this.canvas.height / rect.height;
    const x = (e.clientX - rect.left) * scaleX;
    const y = (e.clientY - rect.top) * scaleY;

    this.ctx.globalCompositeOperation = 'destination-out';
    this.ctx.beginPath();
    this.ctx.arc(x, y, this.brushSize, 0, Math.PI * 2);
    this.ctx.fill();

    this.updateProgress();
  }

  stopScratching() {
    this.isScratching = false;
  }

  updateProgress() {
    const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
    let transparentPixels = 0;

    for (let i = 3; i < imageData.data.length; i += 4) {
      if (imageData.data[i] === 0) transparentPixels++;
    }

    const percentage = (transparentPixels / this.totalPixels) * 100;
    this.updateProgressBar(percentage);

    if (percentage >= 70 && !this.revealed) {
      this.revealPrize();
    }
  }

  updateProgressBar(percentage) {
    const fill = document.querySelector('.progress-fill');
    const text = document.querySelector('.progress-text');
    if (fill) fill.style.width = Math.min(percentage, 100) + '%';
    if (text) text.textContent = Math.round(Math.min(percentage, 100)) + '% Scratched';
  }

  revealPrize() {
    this.revealed = true;
    this.canvas.style.opacity = '0';

    const prizeDisplay = document.querySelector('.prize-display');
    if (prizeDisplay) prizeDisplay.classList.add('revealed');

    const claimBtn = document.querySelector('.btn-claim');
    if (claimBtn && this.prizeData.has_prize) {
      claimBtn.disabled = false;
    }

    this.markAsScratched();
  }

  async markAsScratched() {
    if (!this.prizeData || !this.prizeData.id) return;
    try {
      await fetch(`/api/buyer/scratch-ticket/${this.prizeData.id}/scratch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ scratched: true })
      });
    } catch (err) {
      console.error('Failed to mark ticket as scratched:', err);
    }
  }
}
