// Custom Ticket Design Upload Handler

// Setup file input previews
document.addEventListener('DOMContentLoaded', () => {
  const categories = ['abc', 'efg', 'jkl', 'xyz'];
  const sides = ['front', 'back'];

  categories.forEach(category => {
    sides.forEach(side => {
      const input = document.getElementById(`${category}-${side}`);
      const preview = document.getElementById(`${category}-${side}-preview`);

      input.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
          const reader = new FileReader();
          reader.onload = (event) => {
            preview.innerHTML = `<img src="${event.target.result}" class="preview-image" alt="Preview">`;
          };
          reader.readAsDataURL(file);
        }
      });
    });
  });

  // Load existing designs
  loadExistingDesigns();
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
