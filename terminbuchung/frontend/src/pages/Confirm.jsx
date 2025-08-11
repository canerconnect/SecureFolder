import { useEffect, useState } from 'react';

export default function Confirm() {
  const [status, setStatus] = useState('loading');
  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const booking = params.get('booking');
    const token = params.get('token');
    async function go() {
      const res = await fetch((import.meta.env.VITE_API_BASE || 'http://localhost:4000') + '/api/booking/confirm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ booking, token }),
      });
      setStatus(res.ok ? 'ok' : 'error');
    }
    if (booking && token) go(); else setStatus('error');
  }, []);
  return (
    <div className="max-w-lg mx-auto p-6 mt-10 bg-white rounded shadow text-center">
      {status==='loading' && <div>Bitte warten…</div>}
      {status==='ok' && <div className="text-green-600 text-lg">Ihre Buchung wurde bestätigt.</div>}
      {status==='error' && <div className="text-red-600 text-lg">Bestätigung fehlgeschlagen.</div>}
    </div>
  );
}