# TaskMap

A student productivity app built with Flutter. Manage tasks, track deadlines and generate AI-powered study plans.

## Features

- **Auth:** email/password and Google sign-in, email verification, password recovery, biometric (fingerprint) unlock
- **Tasks:** full CRUD with Cloud Firestore, active/completed toggle, filter and sort
- **AI study planner:** personalised schedules from your tasks, deadlines, available time, focus preference and confidence level, using Llama 3.1 via Groq. Falls back to a rule-based scheduler if the AI service is unavailable. Plans can be saved, edited per session, deleted and regenerated.
- **Calendar:** view tasks and deadlines by date
- **Reminders:** local notifications 2 days, 1 day, 6 hours and 1 hour before a deadline
- **TaskMap Pro:** upgrade by scanning a **NETS QR code** (monthly, quarterly and annual plans). Free users get a daily limit on AI generations; Pro is unlimited.
- **Extras:** offline banner, light/dark theme

## Tech Stack

Flutter · Dart · Firebase Auth · Cloud Firestore · Riverpod · Groq API (`llama-3.1-8b-instant`) · table_calendar · flutter_local_notifications · local_auth · connectivity_plus

## Getting Started

**Prerequisites:** Flutter SDK (Dart ^3.11), an Android/iOS emulator or device, and a Firebase project.

```bash
git clone https://github.com/YOUR_USERNAME/TaskMap-Mobile-App.git
cd TaskMap-Mobile-App
flutter pub get
```

**1. Connect your own Firebase project**

Enable Email/Password and Google sign-in plus Cloud Firestore, then:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**2. Add your Groq API key**

Get a free key at [console.groq.com/keys](https://console.groq.com/keys) and set it in `lib/services/groq_ai_plan_service.dart`.

**3. Run**

```bash
flutter run
```

## Project Structure

```
lib/
├── models/       # Task, user, AI plan, subscription models
├── providers/    # Riverpod state
├── services/     # Firestore, Groq, notifications, biometrics, NETS
├── screens/      # auth, dashboard, tasks, planner, calendar, profile, upgrade
└── theme/
```


## Author

Devananda Thayyullathil, Temasek Polytechnic

## License

Developed for educational purposes.
