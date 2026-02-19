'use strict';

/**
 * ScratchCard - Canvas-based scratch card implementation
 * Supports both mouse (desktop) and touch (mobile) interactions.
 */
class ScratchCard {
  /**
   * @param {string} canvasId - The ID of the canvas element
   * @param {object} options - Configuration options
   * @param {number} [options.brushSize=50] - Brush radius in pixels
   * @param {number} [options.scratchThreshold=70] - Auto-reveal percentage (0-100)
   * @param {function} [options.onProgress] - Callback(percent) on progress update
   * @param {function} [options.onReveal] - Callback when threshold is reached
   */
  constructor(canvasId, options = {}) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) throw new Error('Canvas element not found: ' + canvasId);

    this.ctx = this.canvas.getContext('2d');
    this.isScratching = false;
    this.brushSize = options.brushSize || 50;
    this.scratchThreshold = options.scratchThreshold || 70;
    this.onProgress = options.onProgress || null;
    this.onReveal = options.onReveal || null;
    this.revealed = false;

    this._resizeObserver = null;
    this._init();
  }

  _init() {
    this._sizeCanvas();
    this._drawGreyOverlay();
    this._attachListeners();

    // Re-draw overlay if canvas is resized
    this._resizeObserver = new ResizeObserver(() => {
      this._sizeCanvas();
      this._drawGreyOverlay();
    });
    this._resizeObserver.observe(this.canvas.parentElement);
  }

  _sizeCanvas() {
    const rect = this.canvas.parentElement.getBoundingClientRect();
    this.canvas.width = rect.width;
    this.canvas.height = rect.height;
  }

  _drawGreyOverlay() {
    const { width, height } = this.canvas;

    // Fill grey scratch layer
    this.ctx.globalCompositeOperation = 'source-over';
    this.ctx.fillStyle = '#808080';
    this.ctx.fillRect(0, 0, width, height);

    // "SCRATCH HERE" label
    this.ctx.fillStyle = '#A0A0A0';
    this.ctx.font = `bold ${Math.max(20, Math.floor(width / 12))}px Arial, sans-serif`;
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    this.ctx.fillText('✦ SCRATCH HERE ✦', width / 2, height / 2);
  }

  _attachListeners() {
    // Mouse events (desktop)
    this.canvas.addEventListener('mousedown', (e) => this._startScratch(e));
    this.canvas.addEventListener('mousemove', (e) => this._scratch(e));
    this.canvas.addEventListener('mouseup', () => this._stopScratch());
    this.canvas.addEventListener('mouseleave', () => this._stopScratch());

    // Touch events (mobile)
    this.canvas.addEventListener('touchstart', (e) => this._startScratch(e), { passive: false });
    this.canvas.addEventListener('touchmove', (e) => this._scratch(e), { passive: false });
    this.canvas.addEventListener('touchend', () => this._stopScratch());
    this.canvas.addEventListener('touchcancel', () => this._stopScratch());
  }

  _startScratch(e) {
    if (this.revealed) return;
    this.isScratching = true;
    this._scratch(e);
  }

  _stopScratch() {
    this.isScratching = false;
  }

  _scratch(e) {
    if (!this.isScratching || this.revealed) return;
    e.preventDefault();

    const pos = this._getPosition(e);

    // Erase a circular area using destination-out composite
    this.ctx.globalCompositeOperation = 'destination-out';
    this.ctx.beginPath();
    this.ctx.arc(pos.x, pos.y, this.brushSize, 0, Math.PI * 2);
    this.ctx.fill();

    this._checkProgress();
  }

  _getPosition(e) {
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

  _checkProgress() {
    const { width, height } = this.canvas;
    const imageData = this.ctx.getImageData(0, 0, width, height);
    let transparent = 0;
    const total = width * height;

    // Count transparent (scratched-off) pixels by alpha channel
    for (let i = 3; i < imageData.data.length; i += 4) {
      if (imageData.data[i] === 0) transparent++;
    }

    const percent = (transparent / total) * 100;
    this._updateProgress(percent);

    if (percent >= this.scratchThreshold && !this.revealed) {
      this.reveal();
    }
  }

  _updateProgress(percent) {
    if (typeof this.onProgress === 'function') {
      this.onProgress(percent);
    }
  }

  /** Reveal the prize by fading out the canvas overlay */
  reveal() {
    if (this.revealed) return;
    this.revealed = true;

    // Fade out canvas
    this.canvas.style.transition = 'opacity 0.5s ease';
    this.canvas.style.opacity = '0';
    this.canvas.style.pointerEvents = 'none';

    if (typeof this.onReveal === 'function') {
      this.onReveal();
    }
  }

  /** Programmatically destroy the overlay (instant reveal) */
  destroy() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
    }
  }
}

// Export for module environments (optional)
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ScratchCard;
}
