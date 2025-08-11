import { useState } from 'react';

export default function AdminLogin() {
  const [form, setForm] = useState({ username: '', password: '' });
  const [error, setError] = useState(null);

  async function submit(e) {
    e.preventDefault();
    setError(null);
    const res = await fetch((import.meta.env.VITE_API_BASE || 'http://localhost:4000') + '/api/login', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(form)
    });
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem('token', data.token);
      location.href = '/admin';
    } else setError('Login fehlgeschlagen');
  }

  return (
    <div className="max-w-sm mx-auto p-6 mt-10 bg-white rounded shadow">
      <h1 className="text-xl font-semibold mb-4">Admin Login</h1>
      <form onSubmit={submit} className="grid gap-3">
        <input className="border rounded p-2" placeholder="Benutzername" value={form.username} onChange={(e)=>setForm({ ...form, username: e.target.value })} />
        <input type="password" className="border rounded p-2" placeholder="Passwort" value={form.password} onChange={(e)=>setForm({ ...form, password: e.target.value })} />
        <button className="bg-brand text-white rounded p-2">Login</button>
        {error && <div className="text-red-600 text-sm">{error}</div>}
      </form>
    </div>
  );
}