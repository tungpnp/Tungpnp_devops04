interface DashboardProps {
  token: string;
  onLogout: () => void;
}

export default function Dashboard({ token, onLogout }: DashboardProps) {
  // Decode JWT payload (chỉ để demo UI, không check bảo mật ở FE)
  let username = 'Khách';
  try {
    const payloadBase64 = token.split('.')[1];
    const decodedJson = atob(payloadBase64);
    const payload = JSON.parse(decodedJson);
    username = payload.sub || 'Khách';
  } catch (e) {
    console.error("Token format invalid");
  }

  return (
    <div className="dashboard-container">
      <div className="glass-panel dashboard-panel">
        <div className="dashboard-header">
          <div>
            <h1 className="title" style={{ textAlign: 'left', marginBottom: '4px' }}>Hệ thống Quản trị</h1>
            <p className="subtitle" style={{ textAlign: 'left', marginBottom: '0' }}>Xin chào, <strong style={{color: 'white'}}>{username}</strong>!</p>
          </div>
          <button onClick={onLogout} className="btn-outline">
            Đăng xuất
          </button>
        </div>

        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-title">Trạng thái Java BE</div>
            <div className="stat-value success">Đang kết nối</div>
          </div>
          <div className="stat-card">
            <div className="stat-title">Kafka Broker</div>
            <div className="stat-value warning">Đã gửi tín hiệu</div>
          </div>
          <div className="stat-card">
            <div className="stat-title">Vòng tay hiện tại</div>
            <div className="stat-value success">Hợp lệ</div>
          </div>
        </div>

        <div className="token-section">
          <h3 className="section-title">Chi tiết Vòng tay bảo mật (JWT) - Sẽ ẩn khi chạy trên PROD</h3>
          <div className="token-display">
            <div className="token-value" style={{ fontSize: '13px', color: '#94a3b8' }}>{token}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
