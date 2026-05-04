# frozen_string_literal: true

class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    headers["X-Frame-Options"]        = "SAMEORIGIN"
    headers["X-Content-Type-Options"]  = "nosniff"
    headers["X-XSS-Protection"]        = "1; mode=block"
    headers["Referrer-Policy"]         = "strict-origin-when-cross-origin"
    headers["Permissions-Policy"]      = "camera=(), microphone=(), geolocation=(), payment=()"
    headers["X-Permitted-Cross-Domain-Policies"] = "none"
    headers["X-Download-Options"]      = "noopen"

    [ status, headers, body ]
  end
end
