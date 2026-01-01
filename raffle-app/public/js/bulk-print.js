// Bulk Print Handler
document.addEventListener('DOMContentLoaded', () => {
  const bulkCategorySelect = document.getElementById('bulk-category');
  const bulkStartInput = document.getElementById('bulk-start');
  const bulkCountInput = document.getElementById('bulk-count');
  const bulkPrintBtn = document.getElementById('bulk-print-btn');
  const bulkProgress = document.getElementById('bulk-progress');
  const progressFill = document.getElementById('progress-fill');
  const progressText = document.getElementById('progress-text');

  // Update summary when inputs change
  [bulkCategorySelect, bulkStartInput, bulkCountInput].forEach(element => {
    element.addEventListener('change', updateBulkSummary);
    element.addEventListener('input', updateBulkSummary);
  });

  function updateBulkSummary() {
    const category = bulkCategorySelect.value;
    const start = parseInt(bulkStartInput.value) || 1;
    const count = parseInt(bulkCountInput.value) || 8;
    
    // Ensure count is multiple of 8
    const adjustedCount = Math.floor(count / 8) * 8;
    if (count !== adjustedCount) {
      bulkCountInput.value = adjustedCount;
    }
    
    // Cap at 1000
    const finalCount = Math.min(adjustedCount, 1000);
    if (adjustedCount > 1000) {
      bulkCountInput.value = 1000;
    }
    
    const end = start + finalCount - 1;
    const pages = finalCount / 8;
    
    // Format ticket numbers with leading zeros
    const startTicket = `${category}-${String(start).padStart(6, '0')}`;
    const endTicket = `${category}-${String(end).padStart(6, '0')}`;
    
    // Update summary display
    document.getElementById('summary-range').textContent = `${startTicket} to ${endTicket}`;
    document.getElementById('summary-pages').textContent = pages;
    document.getElementById('summary-paper').textContent = `${pages} sheets (8.5" × 11")`;
  }

  // Initial summary update
  updateBulkSummary();

  // Bulk print button handler
  bulkPrintBtn.addEventListener('click', async () => {
    const category = bulkCategorySelect.value;
    const startNum = parseInt(bulkStartInput.value) || 1;
    const count = parseInt(bulkCountInput.value) || 8;
    
    // Validation
    if (count < 8) {
      alert('Minimum print quantity is 8 tickets (1 page)');
      return;
    }
    
    if (count > 1000) {
      alert('Maximum print quantity is 1000 tickets (125 pages)');
      return;
    }
    
    if (count % 8 !== 0) {
      alert('Ticket count must be a multiple of 8');
      return;
    }
    
    if (startNum < 1 || startNum > 375000) {
      alert('Starting ticket number must be between 1 and 375,000');
      return;
    }
    
    if (startNum + count - 1 > 375000) {
      alert(`Ticket range exceeds category limit. Max end number is 375,000`);
      return;
    }
    
    // Confirm large print jobs
    if (count >= 100) {
      const pages = count / 8;
      const confirmed = confirm(
        `You are about to generate ${count} tickets (${pages} pages).\n` +
        `This may take 1-2 minutes to process.\n\n` +
        `Continue?`
      );
      if (!confirmed) return;
    }
    
    // Disable button and show progress
    bulkPrintBtn.disabled = true;
    bulkPrintBtn.textContent = '⏳ Generating PDF...';
    bulkProgress.style.display = 'block';
    progressFill.style.width = '0%';
    progressText.textContent = 'Preparing tickets...';
    
    try {
      // Call backend API with progress tracking
      await generateBulkPDF(category, startNum, count);
      
      // Success
      progressFill.style.width = '100%';
      progressText.textContent = `✅ Complete! ${count} tickets generated.`;
      
      setTimeout(() => {
        bulkProgress.style.display = 'none';
        bulkPrintBtn.disabled = false;
        bulkPrintBtn.textContent = '🖨️ Generate Bulk Print PDF';
      }, 3000);
      
    } catch (error) {
      console.error('Bulk print error:', error);
      progressText.textContent = `❌ Error: ${error.message}`;
      progressFill.style.background = '#ef4444';
      
      setTimeout(() => {
        bulkProgress.style.display = 'none';
        bulkPrintBtn.disabled = false;
        bulkPrintBtn.textContent = '🖨️ Generate Bulk Print PDF';
        progressFill.style.background = 'linear-gradient(90deg, #667eea, #764ba2)';
      }, 5000);
    }
  });

  async function generateBulkPDF(category, startNum, count) {
    const response = await fetch('/api/admin/tickets/print-bulk', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        category,
        start_number: startNum,
        count,
        paper_type: 'LETTER_8_TICKETS'
      })
    });
    
    if (!response.ok) {
      // Check if response is JSON before parsing
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to generate PDF');
      } else {
        // If not JSON, it might be HTML error page
        const text = await response.text();
        throw new Error(`Server error: ${response.status} ${response.statusText}`);
      }
    }
    
    // Check if response supports streaming for progress
    const contentLength = response.headers.get('content-length');
    const reader = response.body.getReader();
    const chunks = [];
    let receivedLength = 0;
    
    while (true) {
      const { done, value } = await reader.read();
      
      if (done) break;
      
      chunks.push(value);
      receivedLength += value.length;
      
      // Update progress if content-length known
      if (contentLength) {
        const percent = (receivedLength / contentLength) * 100;
        progressFill.style.width = percent + '%';
        progressText.textContent = `Downloading PDF: ${Math.round(percent)}%`;
      } else {
        progressText.textContent = `Downloaded: ${(receivedLength / 1024 / 1024).toFixed(2)} MB`;
      }
    }
    
    // Combine chunks into blob
    const blob = new Blob(chunks, { type: 'application/pdf' });
    
    // Trigger download
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bulk-tickets-${category}-${startNum}-to-${startNum + count - 1}.pdf`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }
});
