import { Link } from 'react-router-dom';

export default function Portfolio() {
  return (
    <div className="portfolio-container">
      {/* Navbar */}
      <nav className="portfolio-nav">
        <div className="nav-logo">TUNGPNP</div>
        <div className="nav-links">
          <Link to="/login" className="btn-primary">
            Hệ thống Quản trị (Login)
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="hero-section">
        <div className="hero-content">
          <h1 className="hero-title">
            <span className="gradient-text">DevOps Engineer</span><br />
            & Software Architect
          </h1>
          <p className="hero-subtitle">
            Xây dựng và vận hành các hệ thống phân tán hiệu năng cao. Chuyên gia về Microservices, K8s, và Cloud Native.
          </p>
        </div>
        
        {/* Floating shapes background */}
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
      </section>

      {/* Skills Section */}
      <section className="skills-section">
        <h2 className="section-heading">Công nghệ & Kỹ năng</h2>
        <div className="skills-grid">
          
          <div className="skill-card">
            <div className="skill-icon" style={{color: '#38bdf8'}}>⎈</div>
            <h3>Kubernetes (K3s)</h3>
            <p>Triển khai cụm Production, Ingress, NodePort, Auto-scaling.</p>
          </div>

          <div className="skill-card">
            <div className="skill-icon" style={{color: '#facc15'}}>☕</div>
            <h3>Java Spring Boot</h3>
            <p>Xây dựng Core API, xử lý nghiệp vụ phức tạp, bảo mật JWT.</p>
          </div>

          <div className="skill-card">
            <div className="skill-icon" style={{color: '#fb923c'}}>⚡</div>
            <h3>Apache Kafka</h3>
            <p>Streaming dữ liệu thời gian thực, Dual Listeners, Message Broker.</p>
          </div>

          <div className="skill-card">
            <div className="skill-icon" style={{color: '#61dafb'}}>⚛️</div>
            <h3>React Vite</h3>
            <p>Phát triển UI/UX hiện đại, Glassmorphism, State Management.</p>
          </div>

        </div>
      </section>
    </div>
  );
}
