import { useEffect, useState } from 'react';

function api(path, opts={}) {
  const token = localStorage.getItem('token');
  return fetch((import.meta.env.VITE_API_BASE || 'http://localhost:4000') + path, {
    ...opts,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...(opts.headers||{}) }
  });
}

export default function Settings() {
  const [settings, setSettings] = useState(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function load() {
      const res = await api('/api/settings');
      if (res.ok) {
        const data = await res.json();
        setSettings(data);
        if (data.color_primary) document.documentElement.style.setProperty('--brand-color', '37 99 235');
      } else if (res.status === 401) {
        location.href = '/admin/login';
      }
    }
    load();
  }, []);

  async function save(e) {
    e.preventDefault();
    setSaving(true);
    const body = { color_primary: settings.color_primary, settings: settings.settings };
    const res = await api('/api/settings', { method: 'PUT', body: JSON.stringify(body) });
    setSaving(false);
    if (res.ok) alert('Gespeichert');
  }

  if (!settings) return null;
  return (
    <div className="max-w-3xl mx-auto p-4">
      <h1 className="text-xl font-semibold mb-4">Einstellungen</h1>
      <form onSubmit={save} className="grid gap-3 bg-white p-4 rounded shadow">
        <div>
          <label className="block text-sm">Hauptfarbe (Hex)</label>
          <input className="border rounded p-2 w-full" value={settings.color_primary || ''} onChange={(e)=>setSettings({ ...settings, color_primary: e.target.value })} />
        </div>
        <div className="grid md:grid-cols-3 gap-3">
          <div>
            <label className="block text-sm">Slotdauer (Min)</label>
            <input type="number" min="5" max="480" className="border rounded p-2 w-full" value={settings.settings.slotDurationMinutes} onChange={(e)=>setSettings({ ...settings, settings: { ...settings.settings, slotDurationMinutes: Number(e.target.value) } })} />
          </div>
          <div>
            <label className="block text-sm">Puffer (Min)</label>
            <input type="number" min="0" max="120" className="border rounded p-2 w-full" value={settings.settings.bufferMinutes} onChange={(e)=>setSettings({ ...settings, settings: { ...settings.settings, bufferMinutes: Number(e.target.value) } })} />
          </div>
          <div>
            <label className="block text-sm">Stornofrist (Std)</label>
            <input type="number" min="0" max="168" className="border rounded p-2 w-full" value={settings.settings.cancellationDeadlineHours} onChange={(e)=>setSettings({ ...settings, settings: { ...settings.settings, cancellationDeadlineHours: Number(e.target.value) } })} />
          </div>
        </div>
        <div>
          <label className="block text-sm">Erinnerungen</label>
          <div className="flex items-center gap-3">
            <input type="checkbox" checked={settings.settings.reminders.enabled} onChange={(e)=>setSettings({ ...settings, settings: { ...settings.settings, reminders: { ...settings.settings.reminders, enabled: e.target.checked } } })} />
            <span>Aktiv</span>
            <input type="number" min="1" max="168" className="border rounded p-2 w-24" value={settings.settings.reminders.hoursBefore} onChange={(e)=>setSettings({ ...settings, settings: { ...settings.settings, reminders: { ...settings.settings.reminders, hoursBefore: Number(e.target.value) } } })} />
            <span>Std vorher</span>
          </div>
        </div>
        <button className="bg-brand text-white rounded p-2" disabled={saving}>{saving ? 'Speichern…' : 'Speichern'}</button>
      </form>
    </div>
  );
}