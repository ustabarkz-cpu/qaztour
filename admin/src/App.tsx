import { Navigate, Route, Routes } from 'react-router-dom';
import './App.css';
import { useAuth } from './contexts/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Locations from './pages/Locations';
import Tours from './pages/Tours';
import Guides from './pages/Guides';
import Bookings from './pages/Bookings';

export default function App() {
  const { session, profile, loading } = useAuth();

  if (loading) {
    return <div className="full-screen-loading">Загрузка...</div>;
  }

  if (!session) {
    return <Login />;
  }

  if (!profile || profile.role !== 'admin') {
    return (
      <div className="full-screen-loading">
        <div className="access-denied">
          <h1>Доступ запрещён</h1>
          <p>
            Эта учётная запись не имеет прав администратора.
            <br />
            Текущая роль: {profile?.role ?? '—'}
          </p>
        </div>
      </div>
    );
  }

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/locations" replace />} />
        <Route path="/locations" element={<Locations />} />
        <Route path="/tours" element={<Tours />} />
        <Route path="/guides" element={<Guides />} />
        <Route path="/bookings" element={<Bookings />} />
        <Route path="*" element={<Navigate to="/locations" replace />} />
      </Route>
    </Routes>
  );
}
