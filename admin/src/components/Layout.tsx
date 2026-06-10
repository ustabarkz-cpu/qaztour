import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const NAV_ITEMS = [
  { to: '/locations', icon: '📍', label: 'Локации' },
  { to: '/tours', icon: '🗺️', label: 'Туры' },
  { to: '/guides', icon: '🧭', label: 'Гиды' },
  { to: '/bookings', icon: '📋', label: 'Брони' },
];

export default function Layout() {
  const { profile, signOut } = useAuth();

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo">🧭</div>
          <div>
            <div className="brand">QazTour</div>
            <div className="brand-sub">Admin</div>
          </div>
        </div>
        <nav>
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => 'nav-item' + (isActive ? ' active' : '')}
            >
              <span className="nav-icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div className="user-name">{profile?.full_name ?? 'Admin'}</div>
          <button className="logout-btn" onClick={signOut}>
            Выйти
          </button>
        </div>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
