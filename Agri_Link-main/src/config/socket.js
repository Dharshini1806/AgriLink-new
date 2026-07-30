const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const chatService = require('../modules/chat/chat.service');
const fcm = require('../utils/fcm');
const logger = require('../utils/logger');

let io;

function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // ── JWT Auth Middleware ────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Authentication required'));
    try {
      socket.user = jwt.verify(token, process.env.JWT_SECRET);
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  // ── Connection Handler ─────────────────────────────────
  io.on('connection', (socket) => {
    logger.info(`Socket connected: user=${socket.user.id} socketId=${socket.id}`);

    // ── Join order chat room ─────────────────────────────
    socket.on('join_order_room', async (orderId) => {
      if (!orderId) return;
      socket.join(`order_${orderId}`);
      socket.currentOrderId = orderId;
      socket.emit('joined', { room: `order_${orderId}`, userId: socket.user.id });
      logger.info(`User ${socket.user.id} joined room order_${orderId}`);
    });

    // ── Leave room ───────────────────────────────────────
    socket.on('leave_order_room', (orderId) => {
      socket.leave(`order_${orderId}`);
    });

    // ── Send message ─────────────────────────────────────
    socket.on('send_message', async ({ orderId, content }) => {
      if (!orderId || !content?.trim()) return;
      try {
        const msg = await chatService.saveMessage({
          orderId,
          senderId: socket.user.id,
          content: content.trim(),
        });
        // Broadcast to all in room
        io.to(`order_${orderId}`).emit('new_message', msg);
        // FCM for offline users
        await fcm.notifyNewMessage(orderId, socket.user.id, content.trim());
      } catch (err) {
        logger.error('send_message error:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ── Typing indicator ─────────────────────────────────
    socket.on('typing_start', ({ orderId }) => {
      socket.to(`order_${orderId}`).emit('user_typing', {
        userId: socket.user.id,
        isTyping: true,
      });
    });

    socket.on('typing_stop', ({ orderId }) => {
      socket.to(`order_${orderId}`).emit('user_typing', {
        userId: socket.user.id,
        isTyping: false,
      });
    });

    // ── Mark messages read ───────────────────────────────
    socket.on('mark_read', async ({ orderId }) => {
      try {
        await chatService.markRead(orderId, socket.user.id);
        io.to(`order_${orderId}`).emit('messages_read', { userId: socket.user.id });
      } catch (err) {
        logger.error('mark_read error:', err);
      }
    });

    // ── Online presence ──────────────────────────────────
    socket.on('disconnect', (reason) => {
      logger.info(`Socket disconnected: user=${socket.user.id} reason=${reason}`);
      if (socket.currentOrderId) {
        socket.to(`order_${socket.currentOrderId}`).emit('user_offline', {
          userId: socket.user.id,
        });
      }
    });
  });

  logger.info('Socket.io initialized');
  return io;
}

function getIO() {
  if (!io) throw new Error('Socket.io not initialized');
  return io;
}

module.exports = { initSocket, getIO };
