// Captcha endpoint
export default function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  const a = Math.floor(Math.random() * 10) + 1;
  const b = Math.floor(Math.random() * 10) + 1;
  // Session may not be available depending on deployment. Consider using cookies or client-side validation if needed.
  res.status(200).json({ question: `What is ${a} + ${b}?`, answer: a + b });
}
