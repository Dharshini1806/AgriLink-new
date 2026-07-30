# 🌾 AgriLink — Smart Farm-to-Buyer Marketplace

A full-stack mobile marketplace that connects farmers directly with buyers using real-time features, geo-filtering, smart pricing, and recipe-to-cart AI.

---

## 🏗️ Architecture

```
agrilink-backend/   → Node.js + Express REST API + Socket.io
agrilink-flutter/   → Flutter (Clean Architecture) mobile app
```

**Stack:**
| Layer | Tech |
|---|---|
| Frontend | Flutter 3.x · Riverpod · go_router · Dio |
| Backend | Node.js · Express · Socket.io |
| Database | PostgreSQL (Neon) |
| Media | Cloudinary |
| Push | Firebase FCM |
| Hosting | Render (backend) |
| Maps | OpenStreetMap + Nominatim |

---

## 🚀 Getting Started

### 1. Backend Setup

```bash
cd agrilink-backend
npm install

# Copy environment template
cp .env.example .env
# → Fill in all values in .env (see section below)

# Run schema in Neon SQL Editor
# → Open schema.sql and run the entire file

# Start development server
npm run dev
```

**Required .env values:**

| Key | Where to get |
|---|---|
| `DATABASE_URL` | [neon.tech](https://neon.tech) → your project → Connection String |
| `JWT_SECRET` | `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` |
| `JWT_REFRESH_SECRET` | Same command, different value |
| `CLOUDINARY_CLOUD_NAME` | [cloudinary.com](https://cloudinary.com) → Dashboard |
| `CLOUDINARY_API_KEY` | Cloudinary → Dashboard |
| `CLOUDINARY_API_SECRET` | Cloudinary → Dashboard |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Firebase Console → Project Settings → Service Accounts → Generate Key → save as `src/config/firebase-service-account.json` |

**Verify it's running:**
```bash
curl http://localhost:10000/health
# → {"status":"ok","timestamp":...}
```

---

### 2. Flutter Setup

```bash
cd agrilink-flutter
flutter pub get

# Configure BASE_URL (backend URL)
# In lib/core/constants/api_endpoints.dart, update defaultValue:
# defaultValue: 'http://10.0.2.2:10000',  ← Android emulator
# defaultValue: 'http://localhost:10000',  ← iOS simulator
# defaultValue: 'https://agrilink-backend.onrender.com', ← Production

# Add Firebase config files:
# Android: android/app/google-services.json
# iOS:     ios/Runner/GoogleService-Info.plist
# (Download from Firebase Console → Project Settings → Your Apps)

# Run on device/emulator
flutter run
```

---

## 📂 Backend Structure

```
src/
├── app.js                    # Express app setup
├── config/
│   ├── db.js                 # PostgreSQL pool
│   ├── cloudinary.js         # Image uploads
│   └── socket.js             # Socket.io gateway
├── middleware/
│   ├── auth.js               # JWT verification
│   ├── role.js               # RBAC
│   ├── validate.js           # Joi schema validation
│   ├── upload.js             # Multer config
│   └── errorHandler.js       # Global error handler
├── modules/
│   ├── auth/                 # Register, Login, Refresh, Logout
│   ├── products/             # CRUD + Geo filter + Cloudinary + Wishlist
│   ├── orders/               # Atomic order creation + Commission
│   ├── users/                # Profile + Seller analytics
│   ├── reviews/              # Reviews + Trust score
│   ├── chat/                 # REST history + unread count
│   ├── smart/                # Pricing + Compare + Recipe-to-cart
│   └── admin/                # Dashboard + Moderation + Fraud
└── utils/
    ├── commission.js         # 1%+1% commission calc
    ├── geoDistance.js        # Haversine formula
    ├── fcm.js                # Firebase push notifications
    └── logger.js             # Winston logger
```

---

## 📱 Flutter Structure

```
lib/
├── core/
│   ├── constants/            # Colors, Theme, Router, API endpoints
│   ├── errors/               # Failures, Exceptions
│   ├── network/              # Dio + Auth/Error/Logging interceptors
│   └── utils/                # Formatters, Validators
├── features/
│   ├── auth/                 # Role select, Login, Register
│   ├── products/             # Feed, Detail, Search, Compare, Wishlist
│   ├── orders/               # Cart, Checkout, Tracking, List
│   ├── chat/                 # Real-time Socket.io chat
│   ├── seller/               # Dashboard, Add Product, Orders, Analytics
│   ├── profile/              # View/Edit profile
│   ├── smart/                # Recipe picker → auto-fill cart
│   └── admin/                # Dashboard, Moderation, Fraud signals
└── shared/
    └── widgets/              # AppButton, AppTextField, ProductCard, etc.
```

---

## 🔑 API Endpoints

| Method | Path | Auth | Role |
|---|---|---|---|
| POST | `/api/auth/register` | ❌ | — |
| POST | `/api/auth/login` | ❌ | — |
| POST | `/api/auth/refresh` | ❌ | — |
| GET | `/api/products` | ✅ | any |
| POST | `/api/products` | ✅ | seller |
| POST | `/api/orders` | ✅ | buyer |
| PATCH | `/api/orders/:id/status` | ✅ | seller |
| GET | `/api/smart/price-suggestion` | ✅ | seller |
| POST | `/api/smart/recipe-to-cart` | ✅ | buyer |
| GET | `/api/smart/compare?ids=a,b,c` | ✅ | any |
| GET | `/api/admin/dashboard` | ✅ | admin |
| GET | `/api/admin/fraud-signals` | ✅ | admin |

---

## 🌐 Deployment (Render)

```bash
# Push backend to GitHub, then:
# Render Dashboard → New Web Service → Connect repo
# Or use render.yaml (already configured)

# Set these env vars in Render Dashboard:
DATABASE_URL=... # (Important: If using Supabase, copy the connection pooler URL on port 6543. Direct connection uses IPv6, which is unreachable on Render)
JWT_SECRET=...
JWT_REFRESH_SECRET=...
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
```

> [!IMPORTANT]
> **Supabase Deployment on Render (IPv6 Connectivity Error):**
> If your database connection fails with `connect ENETUNREACH [IPv6 address]:5432`, it is because Supabase direct connection strings default to IPv6, which is not supported by Render's outbound network.
> **Fix:** In the Supabase Dashboard, go to **Project Settings > Database**, find the **Connection Pooler** section, copy the **Session mode** connection string (which uses port `6543` and resolves to an IPv4 address), and set it as `DATABASE_URL` in your Render Environment settings.


---

## 🧪 Tests

```bash
cd agrilink-backend
npm test
```

---

## 👤 Default Admin

```
Email:    admin@agrilink.in
Password: Admin@1234   ← CHANGE THIS IN PRODUCTION
```

---

## 📞 Socket.io Events

| Event | Direction | Description |
|---|---|---|
| `join_order_room` | Client → Server | Join order chat room |
| `send_message` | Client → Server | Send chat message |
| `new_message` | Server → Client | Broadcast new message |
| `typing_start/stop` | Client → Server | Typing indicator |
| `user_typing` | Server → Client | Show typing indicator |
| `messages_read` | Server → Client | Read receipts |
| `mark_read` | Client → Server | Mark messages read |

---

## 📄 License

MIT — Built for AgriLink by the development team.
