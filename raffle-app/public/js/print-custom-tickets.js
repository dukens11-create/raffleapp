// Print Custom Tickets Handler

/**
 * Load preview of tickets before printing
 */
async function loadPreview() {
  const category = document.getElementById('category').value;
  const startNum = parseInt(document.getElementById('startNumber').value);
  const endNum = parseInt(document.getElementById('endNumber').value);

  // Validation
  if (isNaN(startNum) || isNaN(endNum)) {
    showError('Please enter valid ticket numbers');
    return;
  }

  if (startNum > endNum) {
    showError('Start number must be less than or equal to end number');
    return;
  }

  const ticketCount = endNum - startNum + 1;
  if (ticketCount !== 8) {
    showError('Please select exactly 8 tickets for one sheet (8 tickets per 8.5" × 11" sheet)');
    return;
  }

  if (startNum < 1 || endNum > 375000) {
    showError('Ticket numbers must be between 1 and 375,000');
    return;
  }

  // Show loading
  const previewBtn = event.target;
  previewBtn.disabled = true;
  previewBtn.textContent = 'Loading...';
  previewBtn.classList.add('loading');

  try {
    // Fetch ticket preview data
    const response = await fetch('/api/admin/tickets/preview-custom', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        category: category,
        startNum: startNum,
        endNum: endNum
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to load preview');
    }

    const data = await response.json();
    displayPreview(data.tickets, data.design);

    // Show preview section
    document.getElementById('preview').classList.add('visible');

    // Scroll to preview
    document.getElementById('preview').scrollIntoView({ behavior: 'smooth' });

  } catch (error) {
    console.error('Preview error:', error);
    showError(`Failed to load preview: ${error.message}`);
  } finally {
    // Reset button
    previewBtn.disabled = false;
    previewBtn.textContent = '🔍 Preview Tickets';
    previewBtn.classList.remove('loading');
  }
}

/**
 * Display preview of tickets in the grid
 */
function displayPreview(tickets, design) {
  const grid = document.getElementById('ticketGrid');
  grid.innerHTML = '';

  tickets.forEach(ticket => {
    const ticketDiv = document.createElement('div');
    ticketDiv.className = 'preview-ticket';
    
    // Set background image if design exists
    if (design && design.front_image_base64) {
      ticketDiv.style.backgroundImage = `url(${design.front_image_base64})`;
    }
    
    ticketDiv.innerHTML = `
      <div class="ticket-overlay">
        <div class="ticket-number">${ticket.ticket_number}</div>
        <div class="ticket-barcode">Barcode: ${ticket.barcode}</div>
        <div class="ticket-category">${ticket.category} - $${ticket.price}</div>
      </div>
    `;
    
    grid.appendChild(ticketDiv);
  });
}

/**
 * Generate and download PDF
 */
async function generatePDF() {
  const category = document.getElementById('category').value;
  const startNum = parseInt(document.getElementById('startNumber').value);
  const endNum = parseInt(document.getElementById('endNumber').value);

  // Validation
  if (isNaN(startNum) || isNaN(endNum)) {
    showError('Please enter valid ticket numbers');
    return;
  }

  // Show loading
  const generateBtn = event.target;
  generateBtn.disabled = true;
  generateBtn.textContent = 'Generating PDF...';
  generateBtn.classList.add('loading');

  try {
    const response = await fetch('/api/admin/tickets/print-custom', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        category: category,
        start_number: startNum,
        end_number: endNum,
        paper_type: 'LETTER_8_TICKETS'
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to generate PDF');
    }

    // Download PDF
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `custom-tickets-${category}-${String(startNum).padStart(6, '0')}-${String(endNum).padStart(6, '0')}.pdf`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);

    showSuccess('PDF generated successfully! Download should start automatically.');

  } catch (error) {
    console.error('PDF generation error:', error);
    showError(`Failed to generate PDF: ${error.message}`);
  } finally {
    // Reset button
    generateBtn.disabled = false;
    generateBtn.textContent = '🖨️ Generate PDF';
    generateBtn.classList.remove('loading');
  }
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
