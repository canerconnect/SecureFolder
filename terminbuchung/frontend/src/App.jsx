import { useEffect, useMemo, useState } from 'react';
import dayjs from 'dayjs';

function apiBase() {
  return import.meta.env.VITE_API_BASE || 'http://localhost:4000';
}

function CalendarView({ providerId, selectedDate, onSelectDate, slots, onSelectSlot }) {
  const days = [...Array(7)].map((_, i) => dayjs().startOf('week').add(i, 'day'));
  return (
    <div className="grid gap-4 md:grid-cols-2">
      <div className="p-4 bg-white rounded shadow">
        <h2 className="font-semibold mb-2">Datum wählen</h2>
        <input type="date" value={selectedDate} onChange={(e) => onSelectDate(e.target.value)} className="border rounded p-2" />
      </div>
      <div className="p-4 bg-white rounded shadow">
        <h2 className="font-semibold mb-2">Freie Slots</h2>
        <div className="grid gap-2">
          {slots.map((s) => (
            <button key={s.start} disabled={!s.available} onClick={() => onSelectSlot(s)} className={`p-2 rounded border text-left ${s.available ? 'bg-green-50 border-green-300 hover:bg-green-100' : 'bg-red-50 border-red-300 opacity-60'}`}>
              {dayjs(s.start).format('HH:mm')} - {dayjs(s.end).format('HH:mm')}
            </button>
          ))}
          {slots.length === 0 && <div className="text-sm text-gray-500">Keine Slots verfügbar</div>}
        </div>
      </div>
    </div>
  );
}

function BookingForm({ providerId, slot }) {
  const [form, setForm] = useState({ name: '', email: '', telefon: '', bemerkung: '' });
  const [status, setStatus] = useState(null);
  const datum = dayjs(slot?.start).format('YYYY-MM-DD');
  const uhrzeit = dayjs(slot?.start).format('HH:mm');

  async function submit(e) {
    e.preventDefault();
    setStatus('saving');
    const res = await fetch(`${apiBase()}/api/booking`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ kundeId: providerId, datum, uhrzeit, ...form }),
    });
    if (res.ok) setStatus('ok'); else setStatus('error');
  }

  if (!slot) return null;
  return (
    <form onSubmit={submit} className="p-4 bg-white rounded shadow mt-4 grid gap-3">
      <div className="font-semibold">Termin: {dayjs(slot.start).format('DD.MM.YYYY HH:mm')}</div>
      <input required minLength={2} value={form.name} onChange={(e)=>setForm({ ...form, name: e.target.value })} placeholder="Name" className="border rounded p-2" />
      <input required type="email" value={form.email} onChange={(e)=>setForm({ ...form, email: e.target.value })} placeholder="E-Mail" className="border rounded p-2" />
      <input value={form.telefon} onChange={(e)=>setForm({ ...form, telefon: e.target.value })} placeholder="Telefon (optional)" className="border rounded p-2" />
      <textarea value={form.bemerkung} onChange={(e)=>setForm({ ...form, bemerkung: e.target.value })} placeholder="Bemerkung (optional)" className="border rounded p-2" />
      <button className="bg-brand text-white rounded p-2">Jetzt buchen</button>
      {status==='ok' && <div className="text-green-600">Bitte prüfen Sie Ihre E-Mails zur Bestätigung.</div>}
      {status==='error' && <div className="text-red-600">Fehler bei der Buchung.</div>}
    </form>
  );
}

export default function App() {
  const [providerId, setProviderId] = useState('');
  const [selectedDate, setSelectedDate] = useState(dayjs().format('YYYY-MM-DD'));
  const [slots, setSlots] = useState([]);
  const [selectedSlot, setSelectedSlot] = useState(null);

  useEffect(() => {
    // For MVP, allow entering providerId
    const saved = localStorage.getItem('providerId');
    if (saved) setProviderId(saved);
  }, []);

  useEffect(() => {
    async function load() {
      if (!providerId) return;
      const url = `${apiBase()}/api/slots?kundeId=${providerId}&date=${selectedDate}`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        setSlots(data.slots);
      }
    }
    load();
  }, [providerId, selectedDate]);

  return (
    <div className="max-w-3xl mx-auto p-4">
      <nav className="flex items-center justify-between mb-4">
        <div className="text-xl font-bold" style={{ color: 'rgb(var(--brand-color))' }}>OnlineTermin</div>
        <div className="flex items-center gap-2">
          <input placeholder="Provider ID" className="border rounded p-1" value={providerId} onChange={(e)=>{ setProviderId(e.target.value); localStorage.setItem('providerId', e.target.value); }} />
        </div>
      </nav>
      <CalendarView providerId={providerId} selectedDate={selectedDate} onSelectDate={setSelectedDate} slots={slots} onSelectSlot={setSelectedSlot} />
      <BookingForm providerId={providerId} slot={selectedSlot} />
    </div>
  );
}
