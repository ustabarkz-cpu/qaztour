import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import Modal from '../components/Modal';

interface Tour {
  id: string;
  title: string;
  description: string | null;
  price_per_person: number;
  duration_days: number;
  max_people: number | null;
  photo_url: string | null;
  youtube_360_url: string | null;
  location_id: string;
  guide_id: string;
  locations?: { name: string } | null;
  guides?: { name: string } | null;
}

interface Option {
  id: string;
  name: string;
}

const emptyForm = {
  title: '',
  description: '',
  price_per_person: '',
  duration_days: '',
  max_people: '',
  photo_url: '',
  youtube_360_url: '',
  location_id: '',
  guide_id: '',
};

export default function Tours() {
  const [items, setItems] = useState<Tour[]>([]);
  const [locations, setLocations] = useState<Option[]>([]);
  const [guides, setGuides] = useState<Option[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Tour | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    const [toursRes, locRes, guidesRes] = await Promise.all([
      supabase.from('tours').select('*, locations(name), guides(name)').order('title'),
      supabase.from('locations').select('id, name').order('name'),
      supabase.from('guides').select('id, name').order('name'),
    ]);
    setItems((toursRes.data as Tour[]) ?? []);
    setLocations((locRes.data as Option[]) ?? []);
    setGuides((guidesRes.data as Option[]) ?? []);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const openNew = () => {
    setEditing(null);
    setForm({
      ...emptyForm,
      location_id: locations[0]?.id ?? '',
      guide_id: guides[0]?.id ?? '',
    });
    setShowForm(true);
  };

  const openEdit = (tour: Tour) => {
    setEditing(tour);
    setForm({
      title: tour.title,
      description: tour.description ?? '',
      price_per_person: String(tour.price_per_person),
      duration_days: String(tour.duration_days),
      max_people: tour.max_people?.toString() ?? '',
      photo_url: tour.photo_url ?? '',
      youtube_360_url: tour.youtube_360_url ?? '',
      location_id: tour.location_id,
      guide_id: tour.guide_id,
    });
    setShowForm(true);
  };

  const save = async () => {
    setSaving(true);
    const payload = {
      title: form.title.trim(),
      description: form.description.trim() || null,
      price_per_person: Number(form.price_per_person) || 0,
      duration_days: Number(form.duration_days) || 1,
      max_people: form.max_people.trim() ? Number(form.max_people) : null,
      photo_url: form.photo_url.trim() || null,
      youtube_360_url: form.youtube_360_url.trim() || null,
      location_id: form.location_id,
      guide_id: form.guide_id,
    };
    if (editing) {
      await supabase.from('tours').update(payload).eq('id', editing.id);
    } else {
      await supabase.from('tours').insert(payload);
    }
    setSaving(false);
    setShowForm(false);
    load();
  };

  const remove = async (tour: Tour) => {
    if (!confirm(`Удалить тур «${tour.title}»?`)) return;
    await supabase.from('tours').delete().eq('id', tour.id);
    load();
  };

  return (
    <div>
      <div className="page-header">
        <h1>Туры</h1>
        <button className="primary-btn" onClick={openNew} disabled={!locations.length || !guides.length}>
          + Добавить
        </button>
      </div>

      {loading ? (
        <div className="loading">Загрузка...</div>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Название</th>
              <th>Локация</th>
              <th>Гид</th>
              <th>Цена / чел.</th>
              <th>Дней</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((tour) => (
              <tr key={tour.id}>
                <td>{tour.title}</td>
                <td>{tour.locations?.name ?? '—'}</td>
                <td>{tour.guides?.name ?? '—'}</td>
                <td>{tour.price_per_person.toLocaleString()} ₸</td>
                <td>{tour.duration_days}</td>
                <td className="row-actions">
                  <button onClick={() => openEdit(tour)}>Изменить</button>
                  <button className="danger" onClick={() => remove(tour)}>
                    Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {showForm && (
        <Modal title={editing ? 'Редактировать тур' : 'Новый тур'} onClose={() => setShowForm(false)}>
          <div className="form">
            <label>Название</label>
            <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />

            <label>Описание</label>
            <textarea
              rows={3}
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />

            <div className="form-row">
              <div>
                <label>Цена / чел. (₸)</label>
                <input
                  value={form.price_per_person}
                  onChange={(e) => setForm({ ...form, price_per_person: e.target.value })}
                />
              </div>
              <div>
                <label>Дней</label>
                <input
                  value={form.duration_days}
                  onChange={(e) => setForm({ ...form, duration_days: e.target.value })}
                />
              </div>
            </div>

            <label>Макс. кол-во людей</label>
            <input
              value={form.max_people}
              onChange={(e) => setForm({ ...form, max_people: e.target.value })}
            />

            <label>URL фото</label>
            <input value={form.photo_url} onChange={(e) => setForm({ ...form, photo_url: e.target.value })} />

            <label>URL 360° видео</label>
            <input
              value={form.youtube_360_url}
              onChange={(e) => setForm({ ...form, youtube_360_url: e.target.value })}
            />

            <label>Локация</label>
            <select value={form.location_id} onChange={(e) => setForm({ ...form, location_id: e.target.value })}>
              {locations.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.name}
                </option>
              ))}
            </select>

            <label>Гид</label>
            <select value={form.guide_id} onChange={(e) => setForm({ ...form, guide_id: e.target.value })}>
              {guides.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name}
                </option>
              ))}
            </select>

            <button className="primary-btn" onClick={save} disabled={saving}>
              {saving ? 'Сохранение...' : 'Сохранить'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
