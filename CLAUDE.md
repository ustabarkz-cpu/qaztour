# QazTour — Flutter App (gid_mangystau)

## Проект
Туристический гид по Казахстану. Название **QazTour** (временное, для хакатона).
Слоган: **«Посмотри. Выбери. Поезжай с гидом»**

Аккаунт разработчика: **ustabar.kz@gmail.com**

## Стек
- Flutter + Riverpod + GoRouter
- Supabase (project: `qiwlhmzwbxkldoggxggb`, URL: `https://qiwlhmzwbxkldoggxggb.supabase.co`)
- Firebase (project: `gid-mangystau`, number: `451259000015`)
- Google Sign-In (serverClientId: `451259000015-i9q7b65vej18q1i0tj5u22nkjt1ggcug.apps.googleusercontent.com`)
- Android package: `kz.mangid.gid_mangystau`
- SHA-1: `c870aad4926d6c9b04abdca4d20b265be1ec3c02`

## Структура экранов
- `/login` — Google Sign-In
- `/role-select` — выбор роли (Турист / Гид)
- `/home` — список туров (поиск + горизонт. «Популярные» + вертикальный список)
- `/favorites` — избранное (placeholder)
- `/profile` — профиль пользователя
- `/tour/:id` — детали тура (SliverAppBar + 360° WebView + бронирование)
- `/location/:id` — детали локации
- `/book/:tourId` — создание бронирования
- `/guide/bookings` — панель гида

## Навигация
ShellRoute с 3 вкладками: **Туры / Избранное / Профиль**
Нижнее меню: зелёный индикатор, белый фон.

## Тема
- Primary: `Color(0xFF2E7D32)` (зелёный)
- Background: белый
- Surface: `#F5F5F5`

## Модели данных (Supabase)
- `profiles`: id, full_name, avatar_url, phone, role (tourist/guide)
- `locations`: id, name, description, photo_url, lat, lng, youtube_360_url
- `tours`: id, guide_id, location_id, title, description, price_per_person, duration_days, max_people, photo_url, youtube_360_url
- `bookings`: id, tourist_id, tour_id, travel_date, people_count, status, message

## Ключевые файлы
- `lib/app.dart` — MaterialApp, title: 'QazTour'
- `lib/main.dart` — Firebase.initializeApp + Supabase.initialize
- `lib/firebase_options.dart` — Firebase конфиг
- `lib/core/theme/app_colors.dart` — цвета
- `lib/core/router/app_router.dart` — GoRouter + ShellRoute
- `lib/features/auth/providers/auth_provider.dart` — Google Sign-In, setRole()
- `lib/features/tours/models/tour.dart` — поля: photoUrl, youtube360Url
- `lib/features/tours/providers/tours_provider.dart` — allToursProvider
- `lib/features/home/screens/home_screen.dart` — поиск + популярные + все туры
- `lib/features/tours/screens/tour_detail_screen.dart` — детали тура
- `android/app/google-services.json` — Firebase Android конфиг

## Что сделано
- [x] Google Sign-In + Supabase OAuth
- [x] Выбор роли (Турист/Гид) после входа
- [x] 3-tab навигация (зелёная тема)
- [x] Карточки туров с фото и 360° бейджем
- [x] Горизонтальный скролл «Популярные»
- [x] Поиск по турам
- [x] 360° VR через WebView
- [x] SliverAppBar с фото обложкой
- [x] Экран профиля с ролью

## Что осталось (TODO)
- [ ] Избранное — сделать функциональным (Supabase таблица favorites)
- [ ] «Мои бронирования» в профиле — подключить к реальным данным
- [ ] Иконка приложения (сейчас дефолтная Flutter)
- [ ] Финальное название (QazTour временное)
- [ ] Тестирование на реальном устройстве

## Android
- `android/app/build.gradle.kts`: coreLibraryDesugaringEnabled = true
- `android/settings.gradle.kts`: google-services 4.4.2
