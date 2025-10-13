
# Pawradise

<p align="center">
  <img src="assets/images/logo.png" alt="Pawradise Logo" width="200"/>
</p>

<p align="center">
  A Flutter-based mobile application for pet lovers.
</p>

---

## 📜 Description

Pawradise is a comprehensive mobile app designed to connect pet owners with a variety of pet-related services. Whether you're looking for pet sitters, walkers, or grooming services, Pawradise helps you find trusted care for your furry friends. The app also includes features for scheduling appointments and managing your pet's profile.

---

## ✨ Features

- **User Authentication**: Secure sign-up and login functionality using Firebase Authentication.
- **Pet Profiles**: Create and manage profiles for your pets, including their name, breed, and photos.
- **Service Discovery**: Find local pet services using Google Maps integration.
- **Appointment Scheduling**: Book appointments with service providers using an in-app calendar.
- **Real-Time Notifications**: Receive updates and reminders about your upcoming appointments through Firebase Messaging and local notifications.
- **Location-Based Services**: Utilizes geolocation to help you find services near you.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- A code editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
- An emulator or a physical device to run the application

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/JeremyLing04/Pawradise.git
   ```

2. **Navigate to the project directory:**
   ```sh
   cd Pawradise
   ```

3. **Install the dependencies:**
   ```sh
   flutter pub get
   ```

4. **Run the application:**
   ```sh
   flutter run
   ```

---

## 📁 Folder Structure

The project follows a standard Flutter project structure, with the following key directories:

- **`lib/`**: Contains the main Dart code for the application.
  - **`screens/`**: UI screens for different parts of the app.
  - **`models/`**: Data models for objects like `User`, `Pet`, and `Appointment`.
  - **`services/`**: Business logic for services like Firebase, location, and notifications.
  - **`providers/`**: State management providers.
  - **`constants/`**: Application-wide constants.
  - **`main.dart`**: The entry point of the application.

- **`assets/`**: Includes static assets like images and fonts.
  - **`images/`**: Contains images and logos used in the app.
  - **`fonts/`**: Custom fonts.

- **`test/`**: Contains unit and widget tests for the application.

- **`android/`** and **`ios/`**: Platform-specific configuration files.

---

## 📦 Key Dependencies

- **`flutter`**: The core Flutter framework.
- **`firebase_core`**: For initializing Firebase services.
- **`firebase_auth`**: For user authentication.
- **`cloud_firestore`**: For storing and retrieving data from Firestore.
- **`google_maps_flutter`**: For displaying Google Maps.
- **`location`**: For accessing device location.
- **`table_calendar`**: For creating and managing calendars.
- **`flutter_local_notifications`**: For displaying local notifications.

---

Enjoy using Pawradise!
