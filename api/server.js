const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Allow high-res image data

// ── Database Connection ──
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Test Connection
pool.connect((err, client, release) => {
  if (err) {
    return console.error('❌ Error acquiring client', err.stack);
  }
  console.log('✅ Connected to PostgreSQL (pgAdmin)');
  release();
});

// ── API Routes ──

// 1. Get all Gallery Items
app.get('/api/gallery', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM gallery_items WHERE is_active = TRUE ORDER BY display_order ASC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Upload new Gallery Item
app.post('/api/gallery', async (req, res) => {
  const { title, theme, ratio, src, specs } = req.body;
  try {
    const query = `
      INSERT INTO gallery_items (title, theme, aspect_ratio, image_path, shot_specs)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const values = [title, theme, ratio, src, JSON.stringify(specs)];
    const result = await pool.query(query, values);

    // Log Activity
    await pool.query('INSERT INTO activity_log (action_type, item_id, details) VALUES ($1, $2, $3)',
      ['UPLOAD', result.rows[0].id, `Uploaded: ${title}`]);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Portfolio Server running on http://localhost:${PORT}`);
});
