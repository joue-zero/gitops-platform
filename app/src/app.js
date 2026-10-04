const express = require('express');
const healthRoutes = require('./routes/health');

const app = express();

app.use(express.json());

app.get('/', (req, res) => res.json({ service: 'gitops-app' }));

// Register your routes
app.use('/health', healthRoutes);

module.exports = app;