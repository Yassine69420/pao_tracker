
---

# 📦 PAO Tracker — Product Expiry Manager

A simple and efficient Flutter application to track the expiry of products, get reminders, and view statistics.
Built with **Riverpod**, **SQLite**, and clean architecture.

---

## 🚀 Features

### ✅ Core

* Add / Edit / Delete products
* Save expiry date, open date, notes, and optional photos
* SQLite local storage
* Persistent state with Riverpod
* Home list with remaining time indicators

### 📊 Statistics

* Count expiring soon & expired products
* Usage insights



### 🎨 UI/UX

* Modern floating bottom navigation
* Smooth IndexedStack navigation
* Clean, minimalist layout

---



## 📥 Installation & Setup

1. Clone the project:

```sh
git clone https://github.com/Yassine69420/pao_tracker
```

2. Install dependencies:

```sh
flutter pub get
```

3. Run the project:

```sh
flutter run
```

4. Make sure a device/emulator is connected.

---

## 🗄️ Database (SQLite)

* The app creates a local SQLite database at startup.
* Tables are created automatically via `onCreate`.
* All CRUD operations go through `ProductRepository`.

---

## 📱 Screens

### 🏠 Home

* Shows a list of all products
* Progress indicator based on expiry date

### 📊 Statistics

* Overview of product usage and expiry trends

### ⚙️ Settings

* Theme options (future)
* upload / export (future)

---



## 🧩 Future Improvements

* OCR to auto-detect expiry dates
* Categories & tagging
* Dark/light theme selection

---

## 🤝 Contributions

PRs and feature ideas are welcome!
Open an issue or reach out directly.

---

## 📜 License

MIT License © 2025

---
