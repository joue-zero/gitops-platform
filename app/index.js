const express = require('express');
const app = express();
const PORT = process.env.PORT || 8080;

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
  res.json({ message: 'gitops-platform app', version: process.env.APP_VERSION || 'dev' });
});

app.listen(PORT, () => console.log(`Listening on ${PORT}`));
