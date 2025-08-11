import { createBrowserRouter } from 'react-router-dom';
import App from './App.jsx';
import Confirm from './pages/Confirm.jsx';
import Cancel from './pages/Cancel.jsx';
import AdminLogin from './pages/AdminLogin.jsx';
import AdminDashboard from './pages/AdminDashboard.jsx';
import Settings from './pages/Settings.jsx';

export const router = createBrowserRouter([
  { path: '/', element: <App /> },
  { path: '/confirm', element: <Confirm /> },
  { path: '/cancel', element: <Cancel /> },
  { path: '/admin/login', element: <AdminLogin /> },
  { path: '/admin', element: <AdminDashboard /> },
  { path: '/admin/settings', element: <Settings /> },
]);