const express = require('express');
const healthRoutes = require('./routes/health');

const app = express();

app.use(express.json());

// Register your routes
app.use('/health', healthRoutes);

module.exports = app;