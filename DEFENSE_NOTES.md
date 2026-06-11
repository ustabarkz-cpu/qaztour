# QazTour — шпаргалка для защиты

## Стек и почему так
- **Flutter** — кроссплатформенность (Android/iOS из одной кодовой базы), быстрая разработка UI.
- **Riverpod** — управление состоянием. Каждая фича имеет свои provider'ы (StateNotifierProvider/FutureProvider), которые тянут данные из Supabase и кэшируют их в UI.
- **GoRouter** — декларативная навигация. Используется `ShellRoute` с 3 вкладками (Туры / Избранное / Профиль) — общий нижний навбар, контент вкладок меняется без пересоздания каркаса.
- **Supabase** — backend as a service: Postgres БД + Auth (Google OAuth) + Storage (фото). Не пишем свой сервер — экономим время хакатона, но логика приложения (фильтры, бронирования, роли) — наш код.
- **Firebase** — используется только для Google Sign-In (Firebase Auth/Google Identity), сама БД — Supabase.

## Архитектура (feature-first)
lib/features/<feature>/
  - models/     — Dart-классы данных (TourModel, GuideModel, Booking...) с fromMap() для парсинга JSON из Supabase
  - providers/  — Riverpod providers: запросы к Supabase, бизнес-логика (favorites toggle, booking create)
  - screens/    — UI экраны

Фичи: auth, home, tours, locations, bookings, favorites, profile, guide_mode.

## Поток данных (пример: бронирование)
1. Пользователь на `/location/:id` видит список гидов (`guidesByLocationProvider` — JOIN tours+guides+locations через Supabase).
2. Жмёт "Забронировать" → `/book/:tourId`.
3. `BookingCreateScreen` берёт тур через `tourDetailProvider`, юзер выбирает дату и кол-во людей.
4. По кнопке вызывается `bookingCreateProvider.notifier.create(...)` — INSERT в таблицу `bookings` (tourist_id, tour_id, travel_date, people_count, status='pending').
5. AsyncNotifier ловит результат через `ref.listen` — показывает SnackBar и редиректит на `/my-bookings`.

## Роли (Турист / Гид)
- После Google-входа юзер выбирает роль на `/role-select` → пишется в `profiles.role`.
- Гид видит отдельную панель `/guide/bookings` — список заявок на свои туры, может подтверждать/отклонять (UPDATE bookings.status).

## База данных (Supabase, ключевые таблицы)
- `profiles` (id, full_name, avatar_url, phone, role)
- `locations` (id, name, description, photo_url, lat, lng, youtube_360_url)
- `tours` (id, guide_id, location_id, title, price_per_person, duration_days, max_people, photo_url, youtube_360_url)
- `bookings` (id, tourist_id, tour_id, travel_date, people_count, status, message)
- Связи через FK: tours.location_id → locations.id, tours.guide_id → guides/profiles.

## Фишки, которые стоит показать
- **360° видео** — VrVideoBanner на детальной странице локации/тура (через WebView, YouTube 360°).
- **Избранное** — реализовано через таблицу favorites + `favoritesNotifierProvider` (toggle с оптимистичным обновлением UI).
- **Поиск и "Популярные"** — на главном экране, фильтрация списка туров на клиенте.
- **Админ-панель (React, Vercel)** — отдельное web-приложение для модерации locations/tours/guides/bookings, тоже через Supabase.

## Если спросят "что писали сами, а что low-code"
Всё приложение — Dart-код, написанный вручную (UI, навигация, state management, бизнес-логика бронирований/ролей/избранного). Supabase используется как managed-БД (это нормально и обычная практика — не "no-code конструктор", а просто backend-инфраструктура). Своя логика: модели данных, провайдеры, экраны, роутинг, роли пользователей, флоу бронирования.
