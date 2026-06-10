# QazTour

**«Посмотри. Выбери. Поезжай с гидом»**

Туристический гид по Казахстану — мобильное приложение для поиска локаций и туров,
бронирования с гидом и просмотра 360°-видео достопримечательностей.

## Стек

- **Mobile**: Flutter, Riverpod, GoRouter
- **Backend**: Supabase (Postgres, Auth, Storage, RLS)
- **Auth**: Google Sign-In (Firebase)
- **Admin Panel**: React + TypeScript + Vite, deployed on Vercel

## Структура репозитория

```
gid_mangystau/
├── lib/                  # Flutter-приложение
│   ├── core/             # роутер, тема, supabase-клиент
│   └── features/
│       ├── auth/         # авторизация, выбор роли
│       ├── home/         # главный экран (поиск, локации)
│       ├── locations/    # детали локации, 360° видео
│       ├── tours/        # туры
│       ├── bookings/     # бронирования (турист)
│       ├── guide_mode/   # экраны гида (заявки, мои туры, профиль)
│       └── profile/      # профиль пользователя
├── admin/                # Веб-админка (React + Vite)
│   └── src/
│       ├── pages/        # Локации, Туры, Гиды, Брони
│       └── contexts/     # авторизация (Supabase magic link)
└── android/, ios/, web/  # платформенные обёртки Flutter
```

## Роли пользователей

- **Турист** — просмотр локаций/туров, бронирование, избранное, мои бронирования
- **Гид** — заявки на бронирование, мои туры, профиль гида
- **Admin** (только веб-панель) — управление локациями, турами, гидами, бронированиями

## Запуск

### Mobile (Flutter)

```bash
flutter pub get
flutter run
```

### Admin Panel (React)

```bash
cd admin
npm install
npm run dev
```

## База данных (Supabase)

Таблицы: `profiles`, `locations`, `guides`, `tours`, `bookings`, `favorites`, `reviews`.
Доступ к данным защищён RLS-политиками; административные операции доступны
только пользователям с `profiles.role = 'admin'` через функцию `is_admin()`.
