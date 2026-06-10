import { useState } from 'react';
import { supabase } from '../lib/supabase';

export default function Login() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: window.location.origin },
    });
    setLoading(false);
    if (error) setError(error.message);
    else setSent(true);
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="logo">🧭</div>
        <h1>QazTour Admin</h1>
        <p className="subtitle">Вход для администраторов</p>

        {sent ? (
          <div className="success-box">
            Ссылка для входа отправлена на <b>{email}</b>. Проверьте почту.
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <input
              type="email"
              placeholder="admin@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Отправка...' : 'Получить ссылку для входа'}
            </button>
          </form>
        )}
        {error && <div className="error-box">{error}</div>}
      </div>
    </div>
  );
}
