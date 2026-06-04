# Ritmistas B10 App

A comprehensive gamification and engagement platform for the B10 community, featuring both mobile (Flutter) and web (Next.js) applications with a FastAPI backend.

## Overview

Ritmistas B10 is a points-based engagement system that allows community members to participate in activities, earn points, redeem rewards, and compete in rankings. The platform supports three user roles with different capabilities and features role-based access control.

## Architecture

The project consists of three main components:

- **Mobile App**: Flutter application (iOS, Android, Web, Desktop)
- **Web App**: Next.js 16 application with React 19
- **Backend API**: FastAPI (Python) with PostgreSQL database

## Features

### User Roles

#### 1. User (Role: 2)
Regular community members with access to:

- **Profile Management**: View and edit personal profile, upload profile pictures, manage birth date
- **Points System**: Earn points through activities and code redemption
- **QR Code Scanner**: Scan QR codes to check into activities or redeem rewards
- **Ranking System**: View personal ranking and compete with other members
- **Badge Collection**: Earn and display achievement badges
- **Sector Participation**: Join sectors using invite codes

#### 2. Leader (Líder - Role: 1)
Sector leaders with administrative capabilities:

- **Activity Management**: Create and manage sector activities with check-in codes
- **User Approval**: Approve or reject pending users in their sector
- **User Management**: View sector members, manage user status
- **Points Distribution**: Award points to users manually
- **Code Generation**: Create general redemption codes for the sector
- **Sector Ranking**: View and manage sector-specific rankings
- **User Dashboard**: Access detailed user activity and points history

#### 3. Admin Master (Role: 0)
System administrators with full control:

- **Sector Management**: Create and manage all sectors
- **Leader Management**: Promote users to leaders, assign leaders to sectors
- **Budget Control**: Allocate point budgets to leaders
- **Badge System**: Create badges and award them to users
- **Global Ranking**: View system-wide rankings and statistics
- **Invite System**: Generate system-wide invite codes
- **Audit Reports**: Access comprehensive audit logs and reports
- **User Oversight**: Approve global pending users, manage all users

### Core Features

#### Authentication
- Email/password authentication
- Google Sign-In integration (Firebase Auth)
- JWT token-based authorization
- Password recovery via email
- Invite code system for registration

#### Points & Gamification
- Activity-based point earning
- QR code redemption system
- Manual point distribution by leaders
- Point tracking per sector
- Comprehensive audit trail

#### Activities
- Create activities with dates, locations, and point values
- Activity types: events, meetings, training, etc.
- Check-in system with unique codes
- Activity history tracking

#### Ranking System
- Global ranking across all users
- Sector-specific rankings
- Real-time point updates
- Leaderboard visualization

#### Badge System
- Custom badge creation with icons
- Achievement tracking
- Badge awarding by admins
- Badge display on profiles

## Technology Stack

### Mobile App (Flutter)
- **Framework**: Flutter 3.6+
- **Language**: Dart 3.6+
- **State Management**: Provider
- **Authentication**: Firebase Auth, Google Sign-In
- **Storage**: SharedPreferences, Firebase Storage, Cloud Firestore
- **UI Components**: 
  - CurvedNavigationBar for bottom navigation
  - Material Design 3
  - Custom theme system
- **QR Features**: mobile_scanner, qr_flutter
- **HTTP Client**: http package
- **Platform Support**: Android, iOS, Web, Linux, macOS, Windows

### Web App (Next.js)
- **Framework**: Next.js 16.1.6
- **React**: 19.2.3
- **Language**: TypeScript 5
- **Authentication**: Firebase, JWT with cookies
- **Styling**: CSS Modules
- **Features**:
  - Server-side rendering
  - Protected routes with authentication
  - Responsive design
  - Role-based layouts

### Backend (FastAPI)
- **Framework**: FastAPI
- **Database**: PostgreSQL (production), SQLite (development)
- **ORM**: SQLAlchemy
- **Authentication**: JWT tokens, OAuth2
- **Email**: SMTP integration for password recovery
- **Deployment**: Render.com

## Project Structure

```
ritmistas_app/
├── lib/                          # Flutter mobile app source
│   ├── models/                   # Data models
│   │   └── app_models.dart      # User, Activity, Badge, Ranking models
│   ├── pages/                    # UI screens
│   │   ├── login.dart           # Login page
│   │   ├── home_page.dart       # Role-based home navigation
│   │   ├── perfil_page.dart     # User profile
│   │   ├── ranking_page.dart    # Rankings display
│   │   ├── resgate_page.dart    # QR code scanner
│   │   ├── admin_*.dart         # Leader pages
│   │   └── admin_master_*.dart  # Admin Master pages
│   ├── services/                 # Business logic
│   │   ├── api_service.dart     # Backend API integration
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   ├── widgets/                  # Reusable UI components
│   ├── auth_check.dart          # Authentication guard
│   ├── main.dart                # App entry point
│   └── theme.dart               # App theme configuration
├── ritmistas_web/               # Next.js web app
│   ├── src/
│   │   ├── app/
│   │   │   ├── (authenticated)/ # Protected routes
│   │   │   │   ├── admin/      # Admin Master pages
│   │   │   │   ├── leader/     # Leader pages
│   │   │   │   ├── profile/    # User profile
│   │   │   │   ├── ranking/    # Rankings
│   │   │   │   └── redeem/     # Code redemption
│   │   │   ├── auth/           # Auth callbacks
│   │   │   └── login/          # Login page
│   │   └── lib/
│   │       ├── api.ts          # API client
│   │       ├── auth.tsx        # Auth context
│   │       ├── firebase.ts     # Firebase config
│   │       └── types.ts        # TypeScript types
│   ├── package.json
│   └── next.config.ts
├── android/                     # Android platform files
├── ios/                         # iOS platform files
├── web/                         # Flutter web files
├── windows/                     # Windows platform files
├── linux/                       # Linux platform files
├── macos/                       # macOS platform files
├── assets/                      # App assets
├── pubspec.yaml                 # Flutter dependencies
├── Dockerfile                   # Docker configuration
└── firebase.json                # Firebase configuration
```

## Getting Started

### Prerequisites

- Flutter SDK 3.6 or higher
- Dart SDK 3.6 or higher
- Node.js 20+ (for web app)
- Firebase project configured
- Backend API running

### Mobile App Setup

1. **Install dependencies**:
```bash
flutter pub get
```

2. **Configure Firebase**:
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase config

3. **Run the app**:
```bash
# Development (local backend)
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Production
flutter run --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com
```

4. **Build for production**:
```bash
# Android
flutter build apk --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com

# iOS
flutter build ios --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com

# Web
flutter build web --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com
```

### Web App Setup

1. **Navigate to web directory**:
```bash
cd ritmistas_web
```

2. **Install dependencies**:
```bash
npm install
```

3. **Configure environment**:
Create `.env.local`:
```env
NEXT_PUBLIC_API_URL=https://ritmistas-api.onrender.com
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_auth_domain
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
```

4. **Run development server**:
```bash
npm run dev
```

5. **Build for production**:
```bash
npm run build
npm start
```

## Configuration

### Environment Variables

#### Mobile App (via --dart-define)
- `API_BASE_URL`: Backend API URL (default: https://ritmistas-api.onrender.com)
- `ADMIN_CREATION_KEY`: Key for creating initial admin (development only)

#### Web App (.env.local)
- `NEXT_PUBLIC_API_URL`: Backend API URL
- Firebase configuration variables

### Theme Customization

The mobile app uses a custom theme system defined in `lib/theme.dart`:

- **Colors**: Primary gold/yellow palette with dark background
- **Typography**: Custom font styles and sizes
- **Spacing**: Consistent spacing system
- **Shadows**: Glow effects and elevation
- **Animations**: Smooth transitions and curves

## API Integration

The app communicates with the backend through `ApiService` class which provides methods for:

- Authentication (login, register, Google Sign-In)
- User management (profile, sectors)
- Activities (create, list, check-in)
- Points (redeem codes, distribute)
- Rankings (global, sector-specific)
- Admin operations (badges, sectors, users)

Base URL is configurable via `--dart-define=API_BASE_URL=<url>`

## Deployment

### Mobile App

#### Android
1. Configure signing in `android/app/build.gradle`
2. Build release APK: `flutter build apk --release`
3. Upload to Google Play Console

#### iOS
1. Configure signing in Xcode
2. Build release: `flutter build ios --release`
3. Archive and upload to App Store Connect

#### Web
1. Build: `flutter build web --release`
2. Deploy `build/web/` to hosting service (Firebase Hosting, Netlify, etc.)

### Next.js Web App

1. Build: `npm run build`
2. Deploy to Vercel, Netlify, or any Node.js hosting
3. Configure environment variables on hosting platform

### Docker

Both apps include Dockerfiles for containerized deployment:

```bash
# Mobile web build
docker build -t ritmistas-flutter .

# Next.js web app
cd ritmistas_web
docker build -t ritmistas-web .
```

## Development

### Code Structure

- **Models**: Data classes with JSON serialization
- **Services**: Business logic and API communication
- **Pages**: UI screens with state management
- **Widgets**: Reusable UI components
- **Theme**: Centralized styling system

### Best Practices

- Use `ApiService` for all backend communication
- Store auth tokens in `SharedPreferences`
- Handle errors gracefully with user-friendly messages
- Follow Material Design guidelines
- Maintain consistent theming across the app

## Testing

```bash
# Run Flutter tests
flutter test

# Run web app tests
cd ritmistas_web
npm run lint
```

## Troubleshooting

### Common Issues

1. **Firebase initialization error**: Ensure Firebase is properly configured for your platform
2. **API connection issues**: Verify `API_BASE_URL` is correct and backend is running
3. **Google Sign-In not working**: Check SHA-1/SHA-256 keys are registered in Firebase Console
4. **Build errors**: Run `flutter clean` and `flutter pub get`

### Platform-Specific

- **Android**: Ensure minimum SDK version is 21+
- **iOS**: Requires iOS 12.0+
- **Web**: Enable CORS on backend for web domain

## Contributing

1. Follow Flutter style guide
2. Write meaningful commit messages
3. Test on multiple platforms before submitting
4. Update documentation for new features

## License

[Add your license information here]

## Support

For issues and questions:
- Check existing documentation
- Review backend API docs at `/docs` endpoint
- Contact the development team

## Related Documentation

- [Backend Deployment Guide](../README_DEPLOY.md)
- [User Standardization](../USER_STANDARDIZATION.md)
- Backend API documentation: `https://ritmistas-api.onrender.com/docs`
