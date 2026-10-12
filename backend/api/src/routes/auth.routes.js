const express = require('express');
const { register, login, googleAuth, devLogin } = require('../controllers/auth.controller');

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/google', googleAuth);
router.post('/dev-login', devLogin);

module.exports = router;
