/**
 * scratch-card.js
 * Canvas-based scratch card interaction for scratch-card.html
 */

class ScratchCard {
  constructor(canvasId, options) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    this.isScratching = false;
    this.brushSize = options.brushSize || 50;
    this.scratchThreshold = options.scratchThreshold || 70;
    this.onProgress = options.onProgress || function() {};
    this.onReveal = options.onReveal || function() {};
    this._revealed = false;

    this._init();
  }

  _init() {
    this._resizeCanvas();
    this._drawGreyOverlay();
    this._attachListeners();
  }

  _resizeCanvas() {
    // Match canvas pixel dimensions to its CSS display size
    const rect = this.canvas.getBoundingClientRect();
    this.canvas.width = rect.width;
    this.canvas.height = rect.height;
  }

  _drawGreyOverlay() {
    const { width, height } = this.canvas;
    this.ctx.fillStyle = '#808080';
    this.ctx.fillRect(0, 0, width, height);

    // "SCRATCH HERE" label
    this.ctx.fillStyle = '#A0A0A0';
    this.ctx.font = 'bold 28px Arial, sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText('GRATE ICI / SCRATCH HERE', width / 2, height / 2 - 16);

    this.ctx.font = '18px Arial, sans-serif';
    this.ctx.fillText('✋  Klike epi grate  ✋', width / 2, height / 2 + 20);
  }

  _attachListeners() {
    // Mouse events
    this.canvas.addEventListener('mousedown', (e) => this._startScratch(e));
    this.canvas.addEventListener('mousemove', (e) => this._scratch(e));
    this.canvas.addEventListener('mouseup', () => this._stopScratch());
    this.canvas.addEventListener('mouseleave', () => this._stopScratch());

    // Touch events
    this.canvas.addEventListener('touchstart', (e) => this._startScratch(e), { passive: false });
    this.canvas.addEventListener('touchmove', (e) => this._scratch(e), { passive: false });
    this.canvas.addEventListener('touchend', () => this._stopScratch());
    this.canvas.addEventListener('touchcancel', () => this._stopScratch());
  }

  _startScratch(e) {
    this.isScratching = true;
    this._scratch(e);
  }

  _scratch(e) {
    if (!this.isScratching || this._revealed) return;
    e.preventDefault();

    const pos = this._getPosition(e);
    this.ctx.globalCompositeOperation = 'destination-out';
    this.ctx.beginPath();
    this.ctx.arc(pos.x, pos.y, this.brushSize, 0, Math.PI * 2);
    this.ctx.fill();

    this._checkProgress();
  }

  _stopScratch() {
    this.isScratching = false;
  }

  _getPosition(e) {
    const rect = this.canvas.getBoundingClientRect();
    const scaleX = this.canvas.width / rect.width;
    const scaleY = this.canvas.height / rect.height;

    if (e.type && e.type.includes('touch') && e.touches && e.touches.length > 0) {
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

  _checkProgress() {
    const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
    let transparent = 0;
    const total = this.canvas.width * this.canvas.height;

    for (let i = 3; i < imageData.data.length; i += 4) {
      if (imageData.data[i] === 0) transparent++;
    }

    const percent = (transparent / total) * 100;
    this.onProgress(Math.min(percent, 100));

    if (percent >= this.scratchThreshold && !this._revealed) {
      this._revealed = true;
      this.revealPrize();
    }
  }

  revealPrize() {
    this.canvas.style.transition = 'opacity 0.5s ease';
    this.canvas.style.opacity = '0';

    const prizeDisplay = document.querySelector('.prize-display');
    if (prizeDisplay) {
      prizeDisplay.classList.add('revealed');
    }

    this.onReveal();
  }
}
