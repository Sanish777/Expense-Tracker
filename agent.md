# 🚀 SpendWise AI – Smart Expense Control App

## 📌 Overview
SpendWise AI is a cross-platform (Mobile + Web) application built using Flutter.  
It helps users track expenses, detect overspending habits, and receive AI-powered suggestions to save money.

---

## 🎯 Goals
- Help users understand where their money goes
- Detect unnecessary spending
- Provide actionable suggestions to save money
- Keep the app simple, fast, and offline-first

---

## 👤 Target Users
- Students
- Young professionals
- Anyone struggling to manage daily expenses

---

## 📱 Platforms
- Android
- iOS
- Web (Browser)

---

## 🧠 Core Features (MVP)

### 1. Add Expense
- Input: amount, category, date
- Categories: Food, Transport, Shopping, Bills, Others

### 2. Dashboard
- Total spending (monthly)
- Top spending category
- Simple warning message

### 3. Expense History
- List of all expenses
- Filter by category

### 4. Insights
- Highest spending category
- Weekly summary
- Overspending detection

### 5. Budget Alerts
- Daily or monthly limit
- Warning when limit exceeds

---

## 🤖 AI Features

### 1. Smart Insights
- Analyze spending patterns
- Identify overspending categories

### 2. Suggestions
- “Reduce food spending to save Rs. X”
- “Avoid frequent small expenses”

### 3. Habit Detection
- Detect repeated patterns (e.g., daily snacks)
- Show monthly cost of habits

---

## 🧱 Tech Stack

### Frontend
- Flutter (Dart)

### Storage
- Hive (local database)

### Backend (optional)
- Firebase (Auth + Sync)

### AI Integration
- OpenAI API (or similar)

---

## 📊 Data Model

### Expense
- id
- amount
- category
- date
- note (optional)

---

## 🧩 App Structure

lib/
 ├── screens/
 ├── models/
 ├── services/
 ├── widgets/
 └── main.dart

---

## 🎨 UI Screens

1. Home Dashboard
2. Add Expense Screen
3. Insights Screen
4. History Screen
5. Settings Screen

---

## 🔔 Notifications
- Budget warnings
- Weekly summary alerts

---

## ⚡ Future Features
- Voice input
- Receipt scanning
- Cloud sync
- Gamification (saving streaks)

---

## 🧠 Key Logic

- Detect top spending category
- If category > 40% of total → show warning
- Weekly spending comparison
- Predict savings potential

---

## 🎯 Success Criteria
- User understands spending habits
- User reduces unnecessary expenses
- App is used daily

---