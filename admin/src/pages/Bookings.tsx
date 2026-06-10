import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface Booking {
  id: string;
  date: string;
  people_count: number;
  status: string;
  tours?: {
    title: string;
    price_per_person: number;
    locations?: { name: string } | null;
    guides?: { name: string } | null;
  } | null;
  profiles?: { full_name: string | null } | null;
}

const STATUS_LABELS: Record<string, string> = {
  pending: 'Ожидает',
  accepted: 'Подтверждено',
  rejected: 'Отклонено',
  cancelled: 'Отменено',
};

export default function Bookings() {
  const [items, setItems] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const { data } = await supabase
      .from('bookings')
      .select('*, tours(title, price_per_person, locations(name), guides(name)), profiles(full_name)')
      .order('created_at', { ascending: false });
    setItems((data as Booking[]) ?? []);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const updateStatus = async (id: string, status: string) => {
    await supabase.from('bookings').update({ status }).eq('id', id);
    load();
  };

  return (
    <div>
      <div className="page-header">
        <h1>Бронирования</h1>
      </div>

      {loading ? (
        <div className="loading">Загрузка...</div>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Тур</th>
              <th>Турист</th>
              <th>Локация / Гид</th>
              <th>Дата</th>
              <th>Чел.</th>
              <th>Сумма</th>
              <th>Статус</th>
            </tr>
          </thead>
          <tbody>
            {items.map((b) => (
              <tr key={b.id}>
                <td>{b.tours?.title ?? 'Тур'}</td>
                <td>{b.profiles?.full_name ?? '—'}</td>
                <td>
                  {b.tours?.locations?.name ?? '—'} / {b.tours?.guides?.name ?? '—'}
                </td>
                <td>{b.date}</td>
                <td>{b.people_count}</td>
                <td>{((b.tours?.price_per_person ?? 0) * b.people_count).toLocaleString()} ₸</td>
                <td>
                  <select
                    className={`status-select status-${b.status}`}
                    value={b.status}
                    onChange={(e) => updateStatus(b.id, e.target.value)}
                  >
                    {Object.entries(STATUS_LABELS).map(([value, label]) => (
                      <option key={value} value={value}>
                        {label}
                      </option>
                    ))}
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
