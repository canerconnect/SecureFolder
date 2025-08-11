import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { CustomerProvider } from './contexts/CustomerContext';
import { AuthProvider } from './contexts/AuthContext';
import PublicLayout from './components/layout/PublicLayout';
import AdminLayout from './components/layout/AdminLayout';
import PublicCalendar from './components/public/PublicCalendar';
import AdminCalendar from './components/admin/AdminCalendar';
import AdminBookings from './components/admin/AdminBookings';
import AdminSettings from './components/admin/AdminSettings';
import Login from './components/auth/Login';
import NotFound from './components/common/NotFound';

function App() {
  return (
    <Router>
      <AuthProvider>
        <CustomerProvider>
          <div className="App">
            <Routes>
              {/* Public routes */}
              <Route path="/" element={<PublicLayout />}>
                <Route index element={<PublicCalendar />} />
              </Route>
              
              {/* Admin routes */}
              <Route path="/admin" element={<AdminLayout />}>
                <Route index element={<AdminCalendar />} />
                <Route path="bookings" element={<AdminBookings />} />
                <Route path="settings" element={<AdminSettings />} />
              </Route>
              
              {/* Auth routes */}
              <Route path="/login" element={<Login />} />
              
              {/* 404 */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </div>
        </CustomerProvider>
      </AuthProvider>
    </Router>
  );
}

export default App;