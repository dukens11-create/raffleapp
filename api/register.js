// User registration using Supabase/PostgreSQL
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  let body = req.body;
  if (!body || typeof body !== 'object') {
    try {
      body = JSON.parse(req.body);
    } catch (e) {
      res.status(400).json({ error: 'Invalid JSON' });
      return;
    }
  }
  const { name, phone, password, email } = body;
  if (!name || !phone || !password || !email) {
    res.status(400).json({ error: 'All fields required' });
    return;
  }
  // Hash password (for demo, use bcrypt in production)
  // const hashedPassword = await bcrypt.hash(password, 10);
  // Insert user into Supabase
  const { data, error } = await supabase
    .from('users')
    .insert([{ name, phone, password, email, role: 'user' }]);
  if (error) {
    res.status(500).json({ error: error.message });
    return;
  }
  res.status(200).json({ message: 'User registered', user: data[0] });
}
