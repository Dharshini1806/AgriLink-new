const express = require('express');
const router = express.Router();
const chatService = require('./chat.service');
const verifyToken = require('../../middleware/auth');

router.get('/:orderId/history', verifyToken, async (req, res, next) => {
  try {
    const messages = await chatService.getChatHistory(req.params.orderId, req.user.id, req.query.page, req.query.limit);
    res.json({ data: messages });
  } catch (err) { next(err); }
});

router.get('/unread/count', verifyToken, async (req, res, next) => {
  try {
    const unread = await chatService.getUnreadCount(req.user.id);
    res.json({ unread });
  } catch (err) { next(err); }
});

module.exports = router;
