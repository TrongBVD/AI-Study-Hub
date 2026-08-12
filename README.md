# 🎓 AI StudyHub

<p align="center">
  <img src="https://img.shields.io/badge/React-19.0.0-61DAFB?style=for-the-badge&logo=react&logoColor=black" alt="React 19" />
  <img src="https://img.shields.io/badge/Vite-8.0-646CFF?style=for-the-badge&logo=vite&logoColor=white" alt="Vite" />
  <img src="https://img.shields.io/badge/Node.js-Express_5-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Google_Gemini-AI_RAG-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

🔗 **GitHub Repository**: [https://github.com/TrongBVD/AI-Study-Hub](https://github.com/TrongBVD/AI-Study-Hub)

**AI StudyHub** is an end-to-end, production-grade learning workspace powered by Google Gemini AI. It enables students and educators to organize study documents, collaborate in private workspaces, publish study materials to public libraries, chat with documents using RAG vector search, generate flashcards, and track learning progress.

---

## 🌟 Key Features

- **🔐 Robust Authentication & Security**: Email/OTP verification, Google OAuth 2.0, JWT Access Tokens, HttpOnly Refresh Cookies, and password recovery.
- **📚 Smart Library & Workspace Management**: Personal study libraries (public/private) and collaborative workspaces with role-based permissions (`Admin`, `Editor`, `Contributor`, `Viewer`).
- **📄 Full Document Processing**: Upload PDF, DOCX, TXT, MD, CSV, Audio, and Code files. File duplication detection and 1-click replacement.
- **🤖 Gemini AI-Powered RAG Chatbot**: Chat with your study documents using 768-dimensional vector embeddings (`pgvector` + `match_document_chunks`).
- **🎴 AI Flashcards & Study Tools**: Auto-generate flashcards from study sources tailored to primary document language.
- **🔔 Real-Time In-App Notifications**: Real-time notifications for file uploads, file deletions, workspace role changes, and admin reviews.
- **🛡️ Admin Observability Dashboard**: Full management of users, document moderation queue, activity audit logs, and AI token consumption metrics.
- **🌓 Dynamic UI Aesthetics**: High-contrast glassmorphism dark/light themes, sleek modals, and responsive layouts.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | React 19, React Router 7, Vite 8, Axios, Vanilla CSS (Glassmorphism & High-contrast themes) |
| **Backend** | Node.js, Express 5, Multer, JWT, bcrypt, Nodemailer, Resend API |
| **Database & Storage** | Supabase PostgreSQL, `pgvector` Semantic Search, Supabase Storage Buckets |
| **AI Infrastructure** | Google Gemini Text & Embedding Models (`gemini-2.5-flash`, `text-embedding-004`) |
| **Document Parsing** | `pdf-parse`, `mammoth`, plain text & code parsing |

---

## 🚀 Quick Start Guide

### 1. Prerequisites

- **Node.js** `>= 20.19.0` or `>= 22.12.0`
- **npm** `>= 10.0.0`
- A Supabase Project (PostgreSQL + Storage Bucket)
- A Google Gemini API Key

---

### 2. Database Setup (1-Click SQL)

1. Open your **Supabase Dashboard** -> **SQL Editor**.
2. Run the complete production DDL script provided in **`database_schema.sql`**.  
   *This initializes all 17 production tables, vector search functions (`match_document_chunks`), schema permissions, and RLS configurations.*

---

### 3. Installation

Clone the repository and install dependencies for both Frontend and Backend:

```bash
# Clone the repository
git clone https://github.com/TrongBVD/AI-Study-Hub.git
cd AI-Study-Hub

# Install Backend dependencies
cd BE
npm install

# Install Frontend dependencies
cd ../FE
npm install
```

---

### 4. Environment Configuration

#### Backend Configuration (`BE/.env`):
Copy `BE/.env.example` to `BE/.env` and update your keys:
```bash
cp BE/.env.example BE/.env
```

#### Frontend Configuration (`FE/.env`):
Copy `FE/.env.example` to `FE/.env` and update your API URL:
```bash
cp FE/.env.example FE/.env
```

---

### 5. Running locally

Start the Backend server:
```bash
cd BE
node server.js
```

Start the Frontend dev server in a new terminal:
```bash
cd FE
npm run dev
```

Open `http://localhost:5173` in your browser.

---

## 📁 Repository Layout

```text
AI-Study-Hub/
├── BE/                           # Express 5 Backend API Server
│   ├── .env.example              # Sample environment variables
│   ├── .gitignore                # Git ignore rules for Backend
│   ├── server.js                 # Server entry point
│   └── src/                      # Controllers, Services, Middleware, Routes
├── FE/                           # React 19 + Vite Frontend Application
│   ├── .env.example              # Sample environment variables
│   ├── .gitignore                # Git ignore rules for Frontend
│   └── src/                      # Components, Pages, Context, Utils
├── database_schema.sql           # Complete Supabase PostgreSQL DDL Script (17 tables)
├── PROJECT_DOCUMENTATION.md      # Comprehensive Architecture & API Documentation
├── LICENSE                       # MIT License
└── README.md                     # Project README
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
