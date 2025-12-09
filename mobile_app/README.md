# Recipe Explorer (Flutter)

A native mobile application that allows users to browse, search, and manage recipes. This is the initial scaffold following the Ocean Professional theme.

## Features
- Ocean Professional theming (primary #2563EB, secondary/success #F59E0B, error #EF4444, background #f9fafb, surface #ffffff, text #111827)
- Screens:
  - Home/Browse: Grid of recipe cards with image, title, description, tags
  - Search: Debounced search across title, tags, description
  - Recipe Detail: Hero image, title, ratings placeholder, ingredients, steps, save/unsave
  - Favorites/Saved: List of saved recipes
- Navigation: Material 3 NavigationBar with tabs (Browse, Search, Saved)
- State management: Provider (ChangeNotifier) with debounced search
- Persistence: SharedPreferences to store saved recipe IDs
- Accessibility: High contrast colors, larger tap targets, semantic labels

## Project Structure
```
lib/
  components/       # Reusable UI components (e.g., RecipeCard)
  models/           # Data models
  providers/        # App state (Provider)
  screens/          # Screens for each tab and details
  services/         # Repository and storage services
  theme/            # Theme configuration
assets/
  mock/recipes.json # Local mock data
  images/           # Placeholder images (optional)
```

## Getting Started

1) Ensure Flutter SDK is installed and configured:
```
flutter --version
```

2) Fetch dependencies:
```
flutter pub get
```

3) Run the app:
```
flutter run
```

If running for web or desktop during development, ensure appropriate Flutter support is enabled.

## Notes
- Placeholder images referenced in `assets/mock/recipes.json` (`assets/images/placeholder1.jpg`, etc.) are optional. If not present, the app shows a graceful fallback icon.
- TODO: Integrate external API in `services/recipe_repository.dart` where indicated.
- The app follows strict async usage: no BuildContext usage after `await` inside async methods.

## License
MIT
