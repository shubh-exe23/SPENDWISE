# 💸 Spendwise - Full-Stack Personal Expense Tracker

> **Motto:** *Empowering personal finance through secure, real-time data tracking and smart budget analytics.*

Spendwise is a modern, cross-platform personal finance management application built to help users take control of their daily expenses. Engineered with **Flutter**, powered by a **Python/Flask REST API**, and scaled on a **PostgreSQL (Supabase)** cloud database, it delivers a seamless, high-performance experience with intelligent budget alerts and dynamic data visualization.

## 🚧 Project Status: Production-Ready MVP
Spendwise features a complete frontend-to-backend pipeline with secure authentication, relational data mapping, and cross-platform UI state management. 

---

## ✨ Features in Action

*(Note: The following demonstrations showcase the application's core logic, UI responsiveness, and state management).*

### 1. The Dashboard (Homepage)
A clean, Material Design 3 inspired interface that instantly calculates real-time balances, income, and expenses. Features dynamic currency localization and immediate data retrieval from the PostgreSQL cloud database.
<img width="800" height="1733" alt="Image" src="https://github.com/user-attachments/assets/5cbf4331-75f1-4b39-b47b-a6e480e2bb15" />

### 2. Core Engine: Adding Transactions
Showcases asynchronous state management and fluid UX. Users can effortlessly categorize and record expenses via a custom bottom-sheet form. The UI updates instantaneously without requiring manual page refreshes.
> *(Drop your Adding a Transaction GIF link here)*
<img src="YOUR_GITHUB_IMAGE_LINK_HERE" width="250">

### 3. Data Visualization & Analysis
An interactive analytics dashboard built with `fl_chart`. It aggregates complex transaction histories and allows users to filter by custom date ranges, recalculating totals and updating the donut/pie charts on the fly.
> *(Drop your Analysis GIF link here)*
<img src="YOUR_GITHUB_IMAGE_LINK_HERE" width="250">

### 4. Smart Goals & Push Notifications
The crown jewel of the business logic. The engine actively monitors user spending against custom, time-bound budget thresholds. If a limit is breached, it pushes high-priority system alerts (via `flutter_local_notifications`) directly to the user's screen.
> *(Drop your Goals & Notifications GIF link here)*
<img src="YOUR_GITHUB_IMAGE_LINK_HERE" width="250">

### 5. Settings & Dynamic Theming (Dark Mode)
Demonstrates deep attention to user experience. Includes persistent local storage (`shared_preferences`) for user settings, seamless Dark/Light mode toggling, and global state notifiers that instantly update the entire app's theme without a rebuild.
> *(Drop your Settings/Dark Mode GIF link here)*
<img src="YOUR_GITHUB_IMAGE_LINK_HERE" width="250">

### 6. Secure Authentication Pipeline
A robust login and registration flow engineered with JWT (JSON Web Tokens) and Werkzeug cryptographic password hashing. Includes a custom, email-based OTP recovery system to ensure user data remains completely isolated and secure.
> *(Drop your Login GIF link here)*
<img src="YOUR_GITHUB_IMAGE_LINK_HERE" width="250">

---

## 🛠️ Tech Stack Architecture

**Frontend (Mobile Application):**
* **Framework:** Flutter (Dart)
* **UI/UX:** Material Design 3, `fl_chart` (Data Visualization)
* **State & Local Storage:** `shared_preferences`, ValueNotifiers
* **Hardware APIs:** `flutter_local_notifications`

**Backend (RESTful API & Database):**
* **Framework:** Python 3 & Flask
* **Security:** `Flask-JWT-Extended` (Auth), `Werkzeug` (Password Hashing)
* **Database:** PostgreSQL (Hosted on Supabase)

---

## 🚀 Getting Started (Local Development)

### Prerequisites
* Flutter SDK (3.0+)
* Python 3.10+
* Android Studio / Xcode / VS Code

### 1. Clone the Repository
```bash
git clone [https://github.com/shubh-exe23/SPENDWISE.git](https://github.com/shubh-exe23/SPENDWISE.git)
cd SPENDWISE
