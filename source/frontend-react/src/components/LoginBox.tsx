import { useState } from 'react';

interface LoginBoxProps {
  onLoginSuccess: (token: string) => void;
}

export default function LoginBox({ onLoginSuccess }: LoginBoxProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Gọi API sang backend Java ở cổng 8080
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });

      if (!response.ok) {
        const errorMsg = await response.text();
        throw new Error(errorMsg || 'Đăng nhập thất bại');
      }

      const data = await response.json();
      onLoginSuccess(data.token); // Báo cáo Token lên App.tsx
    } catch (err: any) {
      setError(err.message || 'Lỗi kết nối tới máy chủ');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass-panel">
      <h2 className="title">Chào mừng trở lại</h2>
      <p className="subtitle">Hệ thống Đăng nhập Bảo mật (JWT + Kafka)</p>

      {error && <div className="message error">❌ {error}</div>}

      <form onSubmit={handleLogin}>
        <div className="input-group">
          <input
            type="text"
            className="input-field"
            placeholder="Username (VD: tungpnp)"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            disabled={loading}
            required
          />
        </div>
        
        <div className="input-group">
          <input
            type="password"
            className="input-field"
            placeholder="Password (Nhập mật khẩu của bạn)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={loading}
            required
          />
        </div>

        <button type="submit" className="btn-primary" disabled={loading || !username || !password}>
          {loading ? (
            <>
              <span className="spinner"></span> Đang xử lý...
            </>
          ) : (
            'ĐĂNG NHẬP'
          )}
        </button>
      </form>

    </div>
  );
}
