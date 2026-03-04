# LifeFlow

A comprehensive, offline-first personal management application built with Flutter. "LifeFlow" helps you track your daily routines, manage your finances, visualize your progress, and stay on top of your schedule—all in a beautifully designed, modern interface.

## 🌟 Features

*   **📊 Insightful Dashboard:** Keep track of your daily routine completion progress, your top habit streaks, and a quick summary of your financial balance.
*   **✅ Routine & Task Manager:** 
    *   Create routines with custom times, repeat days, sub-tasks, and priorities.
    *   **Optional Habit Timer:** Set a specific duration for routines and launch a countdown timer directly from the task card.
    *   **Tags & Projects:** Categorize tasks with custom tags (e.g., `#Work`, `#Health`) for better organization.
    *   Track your progress and streaks.
    *   Filter your daily tasks effortlessly with a sleek date carousel.
*   **💰 Finance Tracker:**
    *   Log your income and expenses with customizable categories and **tags**.
    *   Set monthly budget limits for different categories.
    *   Visualize your spending limits and track your overall balance.
*   **📅 Calendar View:** A dedicated calendar screen providing a bird's eye view of your scheduled tasks, habits, and past financial transactions mapped directly to their dates.
*   **🌙 Dark Mode & Theming:** A cohesive design system built on Material 3, supporting both bright light themes and deep dark modes.
*   **🚀 Offline-First:** Powered by Hive, ensuring all your sensitive personal data stays locally on your device with lightning-fast read/write speeds.

## 🛠 Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **State Management:** [Riverpod](https://riverpod.dev/) (`hooks_riverpod`) & [Flutter Hooks](https://pub.dev/packages/flutter_hooks)
*   **Routing:** [GoRouter](https://pub.dev/packages/go_router)
*   **Local Storage:** [Hive](https://docs.hivedb.dev/) (NoSQL Database)
*   **Beautiful Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
*   **Calendar UI:** [table_calendar](https://pub.dev/packages/table_calendar)
*   **Notifications:** `flutter_local_notifications`

## 📁 Project Structure (Feature-First)

The architecture follows a strict "feature-first" organization to keep the codebase modular, scalable, and easy to navigate.

```
lib/
├── core/             # App-wide utilities, theme providers, and constants
├── features/         # The core features of the application
│   ├── dashboard/    # Main entry screen compiling tasks & finance data
│   ├── tasks/        # Models, providers, and UI for the routine tracker
│   ├── finance/      # Models, providers, and UI for the budget & expense tracker
│   └── calendar/     # UI for the monthly interactive calendar
├── main.dart         # Application entry point and Hive initialization
└── router.dart       # GoRouter configuration & navigation bar implementation
```

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.

### Running the App Locally

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd task-manager
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   For the best debugging experience on desktop during development:
   ```bash
   flutter run -d chrome
   ```
   *Note: For the smoothest transitions and animations, run the app in release mode or deploy it to a physical native device (iOS/Android).*
   ```bash
   flutter run -d chrome --release
   ```

## 📱 Sideloading to iPhone (Without a Mac)

This app is built natively for mobile but can easily be enjoyed on an iPhone directly from your PC!

**Method 1: Local Network Web App**
1. Find your Windows PC's local IP address (e.g., `192.168.1.50`).
2. Run the Flutter web server:
   ```bash
   flutter run -d web-server --web-hostname 192.168.1.50 --web-port 8080
   ```
3. On your iPhone, open Safari and navigate to `http://192.168.1.50:8080`.
4. Tap the **Share** button and select **"Add to Home Screen"**. Launch it from your home screen for a full-screen, app-like experience!

**Method 2: Cloud CI/CD (Codemagic + AltStore)**
Push your code to GitHub, connect it to [Codemagic](https://codemagic.io/), and rely on their cloud infrastructure to build the `.ipa` file. You can then use [AltStore](https://altstore.io/) to securely sideload the app onto your iPhone via your Windows PC.
