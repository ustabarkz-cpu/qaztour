import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface Guide {
  id: string;
  name: string;
  photo_url: string | null;
  bio: string | null;
  experience_years: number | null;
  languages: string[] | null;
  rating: number | null;
  reviews_count: number | null;
  phone: string | null;
}

export default function Guides() {
  const [items, setItems] = useState<Guide[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase
      .from('guides')
      .select('*')
      .order('name')
      .then(({ data }) => {
        setItems((data as Guide[]) ?? []);
        setLoading(false);
      });
  }, []);

  return (
    <div>
      <div className="page-header">
        <h1>Гиды</h1>
      </div>

      {loading ? (
        <div className="loading">Загрузка...</div>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th></th>
              <th>Имя</th>
              <th>Опыт</th>
              <th>Языки</th>
              <th>Рейтинг</th>
              <th>Телефон</th>
            </tr>
          </thead>
          <tbody>
            {items.map((g) => (
              <tr key={g.id}>
                <td>
                  <div
                    className="avatar"
                    style={{ backgroundImage: g.photo_url ? `url(${g.photo_url})` : undefined }}
                  >
                    {!g.photo_url && '🧭'}
                  </div>
                </td>
                <td>{g.name}</td>
                <td>{g.experience_years ?? 0} лет</td>
                <td>{(g.languages ?? []).join(', ')}</td>
                <td>
                  ⭐ {(g.rating ?? 0).toFixed(1)} ({g.reviews_count ?? 0})
                </td>
                <td>{g.phone ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
