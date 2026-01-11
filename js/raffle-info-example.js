// To run:
//    npm install express
//    node js/raffle-info-example.js
// Then visit http://localhost:3000/api/public/raffle-info

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

const availableTickets = [
  { id: 1, raffle_id: 1, category_id: 2, status: 'available', available_online: true, number: '001' },
  { id: 2, raffle_id: 1, category_id: 2, status: 'available', available_online: true, number: '002' }
];

app.get('/api/public/raffle-info', (req, res) => {
  const filtered = availableTickets.filter(t =>
    t.status === 'available' &&
    t.available_online &&
    t.raffle_id == 1 &&
    t.category_id == 2
  );
  res.json({tickets: filtered});
});

app.listen(PORT, () => {
  console.log(`Server listening at http://localhost:${PORT}`);
});
