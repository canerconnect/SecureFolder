import { useEffect, useState } from 'react';
import dayjs from 'dayjs';

function api(path, opts={}) {
  const token = localStorage.getItem('token');
  return fetch((import.meta.env.VITE_API_BASE || 'http://localhost:4000') + path, {
    ...opts,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...(opts.headers||{}) }
  });
}

export default function AdminDashboard() {
  const [bookings, setBookings] = useState([]);
  const [form, setForm] = useState({ name: '', email: '', phone: '', startTime: dayjs().add(1,'day').hour(10).minute(0).second(0).toISOString(), durationMinutes: 30, comment: '' });

  useEffect(() => {
    async function load() {
      const res = await api('/api/bookings');
      if (res.ok) {
        const data = await res.json();
        setBookings(data.bookings);
      } else if (res.status === 401) {
        location.href = '/admin/login';
      }
    }
    load();
  }, []);

  async function create(e) {
    e.preventDefault();
    const res = await api('/api/bookings', { method: 'POST', body: JSON.stringify({ ...form, durationMinutes: Number(form.durationMinutes) }) });
    if (res.ok) {
      const data = await res.json();
      setBookings([...bookings, data.booking]);
    }
  }

  return (
    <div className="max-w-5xl mx-auto p-4">
      <nav className="flex items-center justify-between mb-6">
        <div className="text-xl font-bold">Admin</div>
        <div className="text-sm text-gray-500">Buchungen</div>
      </nav>

      <div className="grid md:grid-cols-3 gap-6">
        <form onSubmit={create} className="p-4 bg-white rounded shadow grid gap-2">
          <div className="font-semibold">Manuelle Buchung</div>
          <input required className="border rounded p-2" placeholder="Name" value={form.name} onChange={(e)=>setForm({ ...form, name: e.target.value })} />
          <input required type="email" className="border rounded p-2" placeholder="E-Mail" value={form.email} onChange={(e)=>setForm({ ...form, email: e.target.value })} />
          <input className="border rounded p-2" placeholder="Telefon" value={form.phone} onChange={(e)=>setForm({ ...form, phone: e.target.value })} />
          <input type="datetime-local" className="border rounded p-2" value={dayjs(form.startTime).format('YYYY-MM-DDTHH:mm')} onChange={(e)=>setForm({ ...form, startTime: new Date(e.target.value).toISOString() })} />
          <input type="number" min="5" max="480" step="5" className="border rounded p-2" placeholder="Dauer (Min)" value={form.durationMinutes} onChange={(e)=>setForm({ ...form, durationMinutes: e.target.value })} />
          <textarea className="border rounded p-2" placeholder="Bemerkung" value={form.comment} onChange={(e)=>setForm({ ...form, comment: e.target.value })} />
          <button className="bg-brand text-white rounded p-2">Anlegen</button>
        </form>

        <div className="md:col-span-2 p-4 bg-white rounded shadow">
          <div className="font-semibold mb-2">Termine</div>
          <div className="divide-y">
            {bookings.map((b) => (
              <div key={b.id} className="py-2 flex items-center justify-between">
                <div>
                  <div className="font-medium">{b.name} — {dayjs(b.startTime).format('DD.MM.YYYY HH:mm')}</div>
                  <div className="text-sm text-gray-500">{b.email} · {b.status}</div>
                </div>
              </div>
            ))}
            {bookings.length===0 && <div className="text-sm text-gray-500">Keine Termine.</div>}
          </div>
        </div>
      </div>
    </div>
  );
}