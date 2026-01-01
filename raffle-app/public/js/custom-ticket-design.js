// Custom Ticket Design Upload Handler

// Global variable to store image data during resize
window.originalImageData = null;

// Setup file input previews
document.addEventListener('DOMContentLoaded', () => {
  const categories = ['abc', 'efg', 'jkl', 'xyz'];
  const sides = ['front', 'back'];

  categories.forEach(category => {
    sides.forEach(side => {
      const input = document.getElementById(`${category}-${side}`);
      const preview = document.getElementById(`${category}-${side}-preview`);

      input.addEventListener('change', (e) => {
        handleImageUpload(e.target, preview, category.toUpperCase(), side);
      });
    });
  });

  // Load existing designs
  loadExistingDesigns();
  
  // Setup resize control event listeners
  setupResizeControls();
});

/**
 * Load existing designs from database
 */
async function loadExistingDesigns() {
  try {
    const response = await fetch('/api/admin/ticket-designs');
    if (!response.ok) {
      return; // No existing designs yet
    }

    const data = await response.json();
    
    if (data.designs && data.designs.length > 0) {
      data.designs.forEach(design => {
        const category = design.category.toLowerCase();
        
        // Show front preview if exists
        if (design.front_image_base64) {
          const frontPreview = document.getElementById(`${category}-front-preview`);
          frontPreview.innerHTML = `<img src="${design.front_image_base64}" class="preview-image" alt="Front Preview">`;
        }
        
        // Show back preview if exists
        if (design.back_image_base64) {
          const backPreview = document.getElementById(`${category}-back-preview`);
          backPreview.innerHTML = `<img src="${design.back_image_base64}" class="preview-image" alt="Back Preview">`;
        }
      });
    }
  } catch (error) {
    console.error('Error loading existing designs:', error);
  }
}

/**
 * Handle image upload and show resize controls
 */
function handleImageUpload(fileInput, previewElement, category, side) {
  const file = fileInput.files[0];
  if (!file) return;
  
  const reader = new FileReader();
  reader.onload = (e) => {
    const img = new Image();
    img.onload = () => {
      // Show current dimensions
      const currentDims = `${img.width}px × ${img.height}px`;
      document.getElementById('current-dimensions').textContent = currentDims;
      
      // Show resize controls
      document.getElementById('resize-controls').style.display = 'block';
      
      // Scroll to resize controls
      document.getElementById('resize-controls').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      
      // Check if size is optimal
      const status = checkImageSize(img.width, img.height);
      displaySizeStatus(status);
      
      // Update preview in card
      previewElement.innerHTML = `<img src="${e.target.result}" class="preview-image" alt="Preview">`;
      
      // Update main preview
      document.getElementById('preview-image').src = e.target.result;
      
      // Store original dimensions
      window.originalImageData = {
        width: img.width,
        height: img.height,
        src: e.target.result,
        category,
        side,
        fileInput
      };
      
      // Reset to default fit mode
      document.querySelector('input[name="fitMode"][value="contain"]').checked = true;
      updatePreview('contain');
      
      // Update ticket number preview
      document.querySelector('.ticket-number').textContent = `${category}-000001`;
    };
    img.src = e.target.result;
  };
  reader.readAsDataURL(file);
}

/**
 * Check if image size is optimal
 */
function checkImageSize(width, height) {
  const targetWidth = 153;
  const targetHeight = 396;
  const tolerance = 0.1; // 10% tolerance
  
  const widthRatio = width / targetWidth;
  const heightRatio = height / targetHeight;
  
  if (width < targetWidth * 0.5 || height < targetHeight * 0.5) {
    return {
      type: 'error',
      message: '⚠️ Image is too small - may appear pixelated when printed'
    };
  }
  
  if (Math.abs(widthRatio - 1) < tolerance && Math.abs(heightRatio - 1) < tolerance) {
    return {
      type: 'success',
      message: '✅ Image size is optimal for printing'
    };
  }
  
  if (widthRatio > 2 || heightRatio > 2) {
    return {
      type: 'warning',
      message: '⚠️ Image is very large - will be resized for optimal quality'
    };
  }
  
  return {
    type: 'warning',
    message: '⚠️ Image will be resized to fit ticket dimensions'
  };
}

/**
 * Display size status message
 */
function displaySizeStatus(status) {
  const statusEl = document.getElementById('size-status');
  statusEl.textContent = status.message;
  statusEl.className = `status-message ${status.type}`;
}

/**
 * Setup resize control event listeners
 */
function setupResizeControls() {
  // Handle fit mode changes
  document.querySelectorAll('input[name="fitMode"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
      updatePreview(e.target.value);
    });
  });
  
  // Manual resize controls
  document.getElementById('width-slider').addEventListener('input', (e) => {
    const width = e.target.value;
    document.getElementById('width-value').textContent = width;
    
    if (document.getElementById('lock-aspect').checked && window.originalImageData) {
      const aspectRatio = window.originalImageData.height / window.originalImageData.width;
      const height = Math.round(width * aspectRatio);
      document.getElementById('height-slider').value = height;
      document.getElementById('height-value').textContent = height;
    }
    
    updateManualPreview();
  });
  
  document.getElementById('height-slider').addEventListener('input', (e) => {
    const height = e.target.value;
    document.getElementById('height-value').textContent = height;
    
    if (document.getElementById('lock-aspect').checked && window.originalImageData) {
      const aspectRatio = window.originalImageData.width / window.originalImageData.height;
      const width = Math.round(height * aspectRatio);
      document.getElementById('width-slider').value = width;
      document.getElementById('width-value').textContent = width;
    }
    
    updateManualPreview();
  });
  
  document.getElementById('reset-size').addEventListener('click', () => {
    document.getElementById('width-slider').value = 153;
    document.getElementById('height-slider').value = 396;
    document.getElementById('width-value').textContent = 153;
    document.getElementById('height-value').textContent = 396;
    updateManualPreview();
  });
  
  // Process and save image
  document.getElementById('process-image').addEventListener('click', processAndSaveImage);
}

/**
 * Update preview based on fit mode
 */
function updatePreview(fitMode) {
  const previewImg = document.getElementById('preview-image');
  
  switch(fitMode) {
    case 'contain':
      previewImg.style.objectFit = 'contain';
      previewImg.style.width = '100%';
      previewImg.style.height = '100%';
      break;
    case 'cover':
      previewImg.style.objectFit = 'cover';
      previewImg.style.width = '100%';
      previewImg.style.height = '100%';
      break;
    case 'fill':
      previewImg.style.objectFit = 'fill';
      previewImg.style.width = '100%';
      previewImg.style.height = '100%';
      break;
    case 'none':
      previewImg.style.objectFit = 'none';
      previewImg.style.width = 'auto';
      previewImg.style.height = 'auto';
      break;
  }
}

/**
 * Update preview for manual resize
 */
function updateManualPreview() {
  const width = document.getElementById('width-slider').value;
  const height = document.getElementById('height-slider').value;
  const previewImg = document.getElementById('preview-image');
  
  previewImg.style.width = width + 'px';
  previewImg.style.height = height + 'px';
  previewImg.style.objectFit = 'fill';
}

/**
 * Process and save image
 */
async function processAndSaveImage() {
  if (!window.originalImageData) {
    showError('No image selected');
    return;
  }
  
  const button = document.getElementById('process-image');
  button.disabled = true;
  button.textContent = '⏳ Processing...';
  
  try {
    const fitMode = document.querySelector('input[name="fitMode"]:checked').value;
    const category = window.originalImageData.category;
    const side = window.originalImageData.side;
    
    // Get image as base64
    const canvas = document.createElement('canvas');
    canvas.width = 153;
    canvas.height = 396;
    const ctx = canvas.getContext('2d');
    
    const img = new Image();
    img.src = window.originalImageData.src;
    
    await new Promise(resolve => {
      img.onload = () => {
        // Draw based on fit mode
        if (fitMode === 'contain') {
          const scale = Math.min(canvas.width / img.width, canvas.height / img.height);
          const x = (canvas.width - img.width * scale) / 2;
          const y = (canvas.height - img.height * scale) / 2;
          ctx.fillStyle = 'white';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
        } else if (fitMode === 'cover') {
          const scale = Math.max(canvas.width / img.width, canvas.height / img.height);
          const x = (canvas.width - img.width * scale) / 2;
          const y = (canvas.height - img.height * scale) / 2;
          ctx.drawImage(img, x, y, img.width * scale, img.height * scale);
        } else if (fitMode === 'fill') {
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        } else {
          ctx.fillStyle = 'white';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          const x = (canvas.width - img.width) / 2;
          const y = (canvas.height - img.height) / 2;
          ctx.drawImage(img, x, y);
        }
        resolve();
      };
    });
    
    const processedImage = canvas.toDataURL('image/png');
    
    // Save processed image
    await saveProcessedImage(category, side, processedImage, fitMode);
    
  } catch (error) {
    console.error('Error processing image:', error);
    showError('Failed to process image: ' + error.message);
    button.disabled = false;
    button.textContent = '✅ Apply Resize & Save';
  }
}

/**
 * Save processed image to server
 */
async function saveProcessedImage(category, side, imageBase64, fitMode) {
  try {
    const response = await fetch('/api/admin/ticket-designs/process', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        category,
        side,
        image: imageBase64,
        fitMode,
        targetWidth: 153,
        targetHeight: 396
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to process image');
    }
    
    const result = await response.json();
    showSuccess(`✅ ${category} ${side} image processed and saved successfully!`);
    
    // Update the preview in the category card
    const categoryLower = category.toLowerCase();
    const cardPreview = document.getElementById(`${categoryLower}-${side}-preview`);
    cardPreview.innerHTML = `<img src="${imageBase64}" class="preview-image" alt="Preview">`;
    
    // Hide resize controls
    document.getElementById('resize-controls').style.display = 'none';
    
    // Reset button
    const button = document.getElementById('process-image');
    button.disabled = false;
    button.textContent = '✅ Apply Resize & Save';
    
    // Clear the file input
    if (window.originalImageData && window.originalImageData.fileInput) {
      window.originalImageData.fileInput.value = '';
    }
    window.originalImageData = null;
    
  } catch (error) {
    console.error('Error saving processed image:', error);
    showError('Failed to save image: ' + error.message);
    
    // Reset button
    const button = document.getElementById('process-image');
    button.disabled = false;
    button.textContent = '✅ Apply Resize & Save';
  }
}

/**
 * Save design for a specific category
 */
async function saveDesign(category) {
  const categoryLower = category.toLowerCase();
  const frontInput = document.getElementById(`${categoryLower}-front`);
  const backInput = document.getElementById(`${categoryLower}-back`);

  // Validate that both images are selected
  if (!frontInput.files[0] || !backInput.files[0]) {
    showError('Please select both front and back images before saving.');
    return;
  }

  // Show loading state
  const saveButton = event.target;
  saveButton.disabled = true;
  saveButton.textContent = 'Uploading...';
  saveButton.classList.add('loading');

  try {
    // Convert images to base64
    const frontBase64 = await fileToBase64(frontInput.files[0]);
    const backBase64 = await fileToBase64(backInput.files[0]);

    // Send to server
    const response = await fetch('/api/admin/ticket-designs/upload', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        category: category,
        front_image_base64: frontBase64,
        back_image_base64: backBase64
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to save design');
    }

    const result = await response.json();
    showSuccess(`${category} design saved successfully!`);

    // Reset button state
    saveButton.disabled = false;
    saveButton.textContent = `Save ${category} Design`;
    saveButton.classList.remove('loading');

  } catch (error) {
    console.error('Error saving design:', error);
    showError(`Failed to save design: ${error.message}`);
    
    // Reset button state
    saveButton.disabled = false;
    saveButton.textContent = `Save ${category} Design`;
    saveButton.classList.remove('loading');
  }
}

/**
 * Convert file to base64
 */
function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

/**
 * Show success message
 */
function showSuccess(message) {
  const successDiv = document.getElementById('successMessage');
  successDiv.textContent = message;
  successDiv.style.display = 'block';
  
  // Hide error message
  document.getElementById('errorMessage').style.display = 'none';

  // Auto-hide after 5 seconds
  setTimeout(() => {
    successDiv.style.display = 'none';
  }, 5000);
}

/**
 * Show error message
 */
function showError(message) {
  const errorDiv = document.getElementById('errorMessage');
  errorDiv.textContent = message;
  errorDiv.style.display = 'block';
  
  // Hide success message
  document.getElementById('successMessage').style.display = 'none';

  // Auto-hide after 5 seconds
  setTimeout(() => {
    errorDiv.style.display = 'none';
  }, 5000);
}
