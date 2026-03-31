# GVibe Setup & Development Guide

Welcome to the **GVibe** project! This guide explains how to get the application up and running locally, how to connect a physical device (like a phone on mobile data) using Ngrok, and how our production environment will eventually work.

---

## 1. Running the Backend 🛠️

The backend is built with Node.js and Express, and it runs on port 5000 by default.

**Prerequisites:** Ensure you have Node.js and npm installed.

1. Open a terminal and navigate to the `backend` folder:
   ```bash
   cd /path/to/GVibe/backend
   ```
2. Install the necessary dependencies (if you haven't already):
   ```bash
   npm install
   ```
3. Start the continuous development server (using nodemon):
   ```bash
   npm run dev
   ```
   *Alternatively, run `node server.js` or `npm start`.*

*If successful, you will see a message like `🚀 GVibe server running on port 5000`.*

---

## 2. Using Ngrok for Mobile Testing 🌍

If you are testing the app on an Android emulator or a physical phone connected to the **same Wi-Fi** as your computer, you can use your computer's local IP address (e.g., `http://192.168.x.x:5000`).

However, if your phone is on **Mobile Data (4G/5G)**, it cannot access your local network. To fix this, we use **Ngrok** to expose the backend securely to the internet.

### Setting up Ngrok:
1. **Install Ngrok** via Snap (on Linux): 
   ```bash
   sudo snap install ngrok
   ```
2. Create an account at [dashboard.ngrok.com](https://dashboard.ngrok.com/login).
3. Copy your specific Authtoken from the Ngrok dashboard and authenticate your terminal:
   ```bash
   ngrok config add-authtoken YOUR_TOKEN_HERE
   ```
4. Start the tunnel, pointing it to our backend port (5000):
   ```bash
   ngrok http 5000
   ```
5. Ngrok will provide a "Forwarding" secure HTTPS URL (e.g., `https://levitative-unpresumptuously.ngrok-free.dev`). **Copy this URL.**

### Updating the Frontend (The `.env` file):
Instead of hardcoding the URL into our Dart files, we keep it in an Environment Variables (`.env`) file. This way, you don't accidentally commit your Ngrok URL, and it's easy to change!

1. In the `frontend` folder, create a file named `.env`.
2. Add your new Ngrok URL (with `/api` at the end) into that file like this:
   ```env
   API_BASE_URL=https://levitative-unpresumptuously.ngrok-free.dev/api
   ```
3. Save the file. The Flutter app (via `flutter_dotenv`) will automatically read this URL.

> **Note:** Every time you stop and restart Ngrok, it may give you a brand-new URL (unless you pay for a static domain). Remember to update your `frontend/.env` file and hit Hot Restart in Flutter whenever the Ngrok URL changes!

---

## 3. Environment Variables (.env Files) 🔐

Both the Backend and Frontend require `.env` files to store secrets (like database passwords) and configuration (like URLs). These files are ignored by Git (via `.gitignore`) so your secrets never leak onto GitHub.

### Backend `.env` File
Create a `.env` file in the `backend/` directory. It should look something like this:
```env
PORT=5000
MONGODB_URI=mongodb+srv://<your-username>:<your-password>@cluster.mongodb.net/gvibe
JWT_SECRET=super_secret_jwt_key
```

### Frontend `.env` File
Create a `.env` file in the `frontend/` directory. It should look like this:
```env
API_BASE_URL=https://your-ngrok-url.ngrok-free.dev/api
```
---

## 3. Running the Frontend (Flutter) 📱

The frontend is a Flutter application. 

**Prerequisites:** Ensure you have the Flutter SDK installed and an emulator running (or physical device connected via USB/Wireless Debugging).

1. Open a new terminal and navigate to the `frontend` folder:
   ```bash
   cd /path/to/GVibe/frontend
   ```
2. Fetch the Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
*(Press `r` in the terminal to Hot Reload, or `R` to Hot Restart).*

---

## 4. The Future: Production Stage 🚀

Right now, we are relying on our personal computers to host the database and the Node.js API. 

When GVibe is ready for **Production** (real users downloading the app), we can no longer run it on our laptops. Here is how we will migrate:

### 1. Database (MongoDB)
*   **Current:** Local MongoDB or an initial cloud cluster.
*   **Production:** We will host the app's database completely in the cloud using a service like **MongoDB Atlas**. This ensures high availability, automatic backups, and fast global access.

### 2. Backend Hosting (Node.js API)
*   **Current:** `localhost:5000` via Ngrok.
*   **Production:** We will deploy our Node backend to cloud providers like **Render.com, Heroku, AWS, or DigitalOcean**. 
    *   This gives us an always-online server (24/7 endpoint).
    *   The `tunnelUrl` in Flutter will be permanently replaced with a real production domain, e.g., `https://api.gvibe.com`.

### 3. Frontend App Distribution
*   **Production:** The Flutter code will be compiled into an Android App Bundle (`.aab`) and an iOS `.ipa` file. These bundled files will be uploaded to the **Google Play Store** and **Apple App Store** respectively. Users will simply download the app as usual, and it will transparently talk to our cloud backend in the background.
