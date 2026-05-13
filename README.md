# Earn Rupai 💰

> A task-earning platform where students complete tasks and earn rewards

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Ready-green)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**By: [Leela Sai Vardhan](https://github.com/Leela-Sai-Vardhan)**

---

## 📱 Overview

Earn Rupai is a production-ready earning platform with **150+ active students** where users complete tasks (surveys, app installs, quizzes) and earn real money. I built the entire stack from Flutter UI to Node.js backend to Supabase database, handling authentication, wallet systems, referral logic, and Play Store deployment.

This is my flagship project - a real product with real users, not just a portfolio piece.

---

## 🎯 Key Features

| Feature | Description |
|---------|-------------|
| **🎯 Task System** | Browse and filter tasks by category, complete with external links |
| **💰 Wallet** | Track earnings, pending rewards, and available balance |
| **👥 Referral Program** | Invite friends and earn when they complete tasks |
| **🔐 Authentication** | Secure email/password auth with Supabase |
| **📊 Admin Panel** | Create tasks, approve completions, manage users |
| **🚀 Production Deployed** | Live on Play Store with real users |

---

## 🏆 Impact

- **150+ active students** using the app daily
- **Real money transfers** via UPI wallet system
- **Organic growth** - users invite friends (referral-driven)
- **Self-taught journey** - learned Flutter and backend to build this

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Mobile** | Flutter, Dart |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Node.js + Express |
| **Database** | Supabase (PostgreSQL + Auth + RLS) |
| **Authentication** | Supabase Auth (JWT) |
| **Architecture** | Clean Architecture |
| **Deployment** | Play Store, Vercel |

---

## 📂 Project Structure

### Mobile App (`/earnrupai`)

```
lib/
├── main.dart
├── core/
│   ├── theme.dart
│   └── constants.dart
├── data/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── models/
│   └── repositories/
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── tasks/
│   │   ├── wallet/
│   │   └── profile/
│   └── widgets/
└── routes/
    └── app_router.dart
```

### Backend (`/earnrupai-backend`)

```
src/
├── index.js              # Entry point
├── routes/
│   ├── auth.js          # Authentication
│   ├── tasks.js         # Task CRUD
│   ├── wallet.js        # Wallet operations
│   └── admin.js         # Admin endpoints
├── controllers/         # Business logic
├── middleware/          # Auth, validation
└── config/              # Supabase client
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Node.js 18+
- Supabase project

### Quick Start

```bash
# 1. Clone and setup mobile app
cd earnrupai
flutter pub get

# 2. Setup backend
cd ../earnrupai-backend
npm install
cp .env.example .env
# Configure Supabase credentials in .env

# 3. Run backend
npm run dev

# 4. Run mobile app
cd ../earnrupai
flutter run
```

### Environment Variables

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
JWT_SECRET=your_jwt_secret
PORT=3000
```

---

## 🗄️ Database Schema

### Key Tables

```sql
-- Users
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE,
  phone TEXT,
  referral_code TEXT,
  referred_by UUID,
  wallet_balance DECIMAL DEFAULT 0
)

-- Tasks
tasks (
  id UUID PRIMARY KEY,
  title TEXT,
  category TEXT,
  description TEXT,
  reward_amount DECIMAL,
  external_url TEXT,
  status TEXT DEFAULT 'active',
  max_completions INT
)

-- User Task Progress
user_tasks (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users,
  task_id UUID REFERENCES tasks,
  status TEXT,  -- 'in_progress', 'completed', 'approved'
  completed_at TIMESTAMP
)

-- Wallet Transactions
wallet_ledger (
  id UUID PRIMARY KEY,
  user_id UUID,
  amount DECIMAL,
  type TEXT,  -- 'earning', 'withdrawal', 'referral_bonus'
  status TEXT
)
```

---

## 🔐 Security

- **Row Level Security (RLS)**: Users can only access their own data
- **JWT Authentication**: Secure API access with token validation
- **Input Validation**: All API inputs sanitized with express-validator
- **Helmet & CORS**: Security headers configured
- **Rate Limiting**: Auth endpoints protected from brute force

---

## 🤔 Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| **Race conditions** | Added database constraints + debounced UI to prevent double submissions |
| **Security** | Implemented RLS policies at database level - can't be bypassed from app |
| **User management** | Built admin dashboard for approving task completions and handling disputes |
| **Referral tracking** | Created self-referential user table with referral codes |
| **Payment integration** | UPI withdrawal system with pending/approved workflow |

---

## 📈 What I Learned

- **Full-stack development**: Built entire product end-to-end, not just UI
- **Database design**: Schema modeling, relationships, indexing, RLS
- **Production deployment**: Play Store submission, Vercel deployment, error tracking
- **User management**: Handling real users, feedback, bug fixes, feature requests
- **Self-teaching**: Learned Flutter and Supabase from docs to build this real product
- **Business thinking**: Not just code - product design, monetization, user acquisition

---

## 🔜 Future Enhancements

- [ ] Add more payment gateways (Paytm, GPay)
- [ ] Push notifications for new tasks
- [ ] Leaderboard for top earners
- [ ] Task verification automation (screenshot validation)
- [ ] Dark mode

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👤 Author

**Leela Sai Vardhan**
- GitHub: [@Leela-Sai-Vardhan](https://github.com/Leela-Sai-Vardhan)
- Email: leelasaisvardhan@gmail.com
- Website: [earnrupai.com](https://earnrupai.com)

---

*Built with ❤️ - From zero to 150 users, one learning at a time*