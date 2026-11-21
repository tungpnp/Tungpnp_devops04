import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginBox from './components/LoginBox';
import Dashboard from './components/Dashboard';
import Portfolio from './components/Portfolio';
import './index.css';

function App() {
  const [token, setToken] = useState<string | null>(localStorage.getItem('jwt_token'));

  // Đồng bộ Token vào bộ nhớ trình duyệt mỗi khi thay đổi
  useEffect(() => {
    if (token) {
      localStorage.setItem('jwt_token', token);
    } else {
      localStorage.removeItem('jwt_token');
    }
  }, [token]);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Portfolio />} />
        
        <Route path="/login" element={
          token ? <Navigate to="/dashboard" replace /> : (
            <div className="login-container">
              <LoginBox onLoginSuccess={setToken} />
            </div>
          )
        } />
        
        <Route path="/dashboard" element={
          token ? <Dashboard token={token} onLogout={() => setToken(null)} /> : <Navigate to="/login" replace />
        } />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
