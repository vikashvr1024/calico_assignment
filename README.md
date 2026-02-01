# Calico Pet Vaccination Manager

A premium, pixel-perfect Flutter application designed for managing pet vaccine verifications with AI-powered analysis and robust offline-first capabilities.

## 🚀 Key Features
- **AI-Powered Analysis**: Uses Google Gemini API to automatically extract vaccine names, issue dates, and due dates from medical reports/certificates.
- **Offline-First Support**: Seamlessly cache pets and vaccines locally using SQLite. Add new records while offline; they will automatically sync when connectivity is restored.
- **Dynamic UI Feedbacks**: Real-time sync status banners and network connectivity indicators.
- **Premium Design**: Dark mode support, custom headers, and high-fidelity typography (Poppins) following strictly hierarchical design principles.

## 🛠️ Tech Stack
### Frontend
- **Framework**: Flutter
- **Local Database**: `sqflite` (SQLite) for persistent offline storage.
- **Connectivity**: `connectivity_plus` for real-time network monitoring.
- **State Management**: Service-based repository pattern for clean data flow.

### Backend
- **Framework**: Node.js (Express)
- **Database**: PostgreSQL (Primary server-side storage)
- **AI/ML**: Google Gemini API (`gemini-2.0-flash`) for multi-modal document analysis.
- **Storage**: Local filesystem for persist uploaded vaccine images.

## 🧪 OCR / AI Approach
Initially, the project used Google ML Kit for on-device OCR. To significantly improve accuracy and handle complex medical layouts, the system was migrated to a **Server-Side AI Analysis** model:
1.  **Image Upload**: The mobile app uploads the document to the backend.
2.  **Multimodal Analysis**: The backend invokes the Google Gemini Pro Vision model (`gemini-2.0-flash`).
3.  **Data Extraction**: The AI is prompted to return a structured JSON response containing:
    -   Type (Vaccination/Deworming)
    -   Vaccine Name
    -   Date Issued
    -   Next Due Date
4.  **Verification**: The extracted data is returned to the app for user verification before final submission.

## 📦 Setup Instructions

### 1. Backend (Node.js + PostgreSQL)
1.  Ensure **PostgreSQL** is installed and running.
2.  Navigate to the `backend` directory.
3.  Update `config/db.js` with your PostgreSQL credentials.
4.  Add your `GEMINI_API_KEY` to the `.env` file in the `backend` folder.
5.  Initialize the database: `node setupDb.js` (Creates tables and seeds initial pets).
6.  Start the server: `node server.js`.

### 2. Frontend (Flutter)
1.  Ensure you have the Flutter SDK installed.
2.  Run `flutter pub get` to install dependencies.
3.  Ensure the `baseUrl` in `lib/services/api_service.dart` points to your machine's IP (e.g., `http://10.0.2.2:3000` for Android Emulator).
4.  Launch the app: `flutter run`.

## ⚠️ Known Limitations
- **Image Persistence**: If a user clears the app's cache or deletes local image files before a background sync completes, the sync for that specific record may fail.
- **Fixed API Key**: The current implementation uses a developer API key on the backend; in production, this would be managed via a secure secrets manager.
- **Dynamic Field Logic**: While Gemini is highly accurate, it may sometimes misinterpret handwritten dates if the handwriting is severely damaged.



