import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import Modal from '../components/Modal';

interface Location {
  id: string;
  name: string;
  description: string | null;
  photo_url: string | null;
  youtube_360_url: string | null;
  lat: number | null;
  lng: number | null;
}

const emptyForm = {
  name: '',
  description: '',
  photo_url: '',
  youtube_360_url: '',
  lat: '',
  lng: '',
};

export default function Locations() {
  const [items, setItems] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<Location | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    const { data } = await supabase.from('locations').select('*').order('name');
    setItems((data as Location[]) ?? []);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const openNew = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowForm(true);
  };

  const openEdit = (loc: Location) => {
    setEditing(loc);
    setForm({
      name: loc.name,
      description: loc.description ?? '',
      photo_url: loc.photo_url ?? '',
      youtube_360_url: loc.youtube_360_url ?? '',
      lat: loc.lat?.toString() ?? '',
      lng: loc.lng?.toString() ?? '',
    });
    setShowForm(true);
  };

  const save = async () => {
    setSaving(true);
    const payload = {
      name: form.name.trim(),
      description: form.description.trim() || null,
      photo_url: form.photo_url.trim() || null,
      youtube_360_url: form.youtube_360_url.trim() || null,
      lat: form.lat.trim() ? Number(form.lat) : null,
      lng: form.lng.trim() ? Number(form.lng) : null,
    };
    if (editing) {
      await supabase.from('locations').update(payload).eq('id', editing.id);
    } else {
      await supabase.from('locations').insert(payload);
    }
    setSaving(false);
    setShowForm(false);
    load();
  };

  const remove = async (loc: Location) => {
    if (!confirm(`Удалить локацию «${loc.name}»?`)) return;
    await supabase.from('locations').delete().eq('id', loc.id);
    load();
  };

  return (
    <div>
      <div className="page-header">
        <h1>Локации</h1>
        <button className="primary-btn" onClick={openNew}>
          + Добавить
        </button>
      </div>

      {loading ? (
        <div className="loading">Загрузка...</div>
      ) : (
        <div className="card-grid">
          {items.map((loc) => (
            <div key={loc.id} className="item-card">
              <div
                className="item-photo"
                style={{
                  backgroundImage: loc.photo_url ? `url(${loc.photo_url})` : undefined,
                }}
              >
                {loc.youtube_360_url && <span className="badge">360°</span>}
              </div>
              <div className="item-body">
                <h3>{loc.name}</h3>
                <p>{loc.description}</p>
              </div>
              <div className="item-actions">
                <button onClick={() => openEdit(loc)}>Изменить</button>
                <button className="danger" onClick={() => remove(loc)}>
                  Удалить
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <Modal title={editing ? 'Редактировать локацию' : 'Новая локация'} onClose={() => setShowForm(false)}>
          <div className="form">
            <label>Название</label>
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />

            <label>Описание</label>
            <textarea
              rows={3}
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />

            <label>URL фото</label>
            <input value={form.photo_url} onChange={(e) => setForm({ ...form, photo_url: e.target.value })} />

            <label>URL 360° видео</label>
            <input
              value={form.youtube_360_url}
              onChange={(e) => setForm({ ...form, youtube_360_url: e.target.value })}
            />

            <div className="form-row">
              <div>
                <label>Широта (lat)</label>
                <input value={form.lat} onChange={(e) => setForm({ ...form, lat: e.target.value })} />
              </div>
              <div>
                <label>Долгота (lng)</label>
                <input value={form.lng} onChange={(e) => setForm({ ...form, lng: e.target.value })} />
              </div>
            </div>

            <button className="primary-btn" onClick={save} disabled={saving}>
              {saving ? 'Сохранение...' : 'Сохранить'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
