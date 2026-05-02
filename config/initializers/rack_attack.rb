# frozen_string_literal: true

class Rack::Attack
  ### --- Cache store ---
  # Use Rails cache (solid_cache in prod, memory in dev)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### --- Safelist ---
  # Allow all requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end if Rails.env.development?

  ### --- Throttles ---

  # Global: 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  # Login: 5 attempts per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # Login: 5 attempts per 15 minutes per username
  throttle("logins/username", limit: 5, period: 15.minutes) do |req|
    if req.path == "/login" && req.post?
      req.params.dig("username")&.to_s&.downcase&.strip.presence
    end
  end

  # Registration: 3 per hour per IP
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/register" && req.post?
  end

  # Password-related: 5 per 15 minutes per IP
  throttle("passwords/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path.start_with?("/password") && req.post?
  end

  # Posting: 10 posts per 5 minutes per IP
  throttle("posts/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path.match?(%r{/threads/.*/posts}) && req.post?
  end

  # Thread creation: 5 per 15 minutes per IP
  throttle("threads/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path.match?(%r{/subforums/.*/threads}) && req.post?
  end

  # Private messages: 10 per 5 minutes per IP
  throttle("messages/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/messages" && req.post?
  end

  # File uploads: 5 per 10 minutes per IP
  throttle("uploads/ip", limit: 5, period: 10.minutes) do |req|
    req.ip if req.path.match?(%r{/attachments}) && req.post?
  end

  # Reports: 5 per 15 minutes per IP
  throttle("reports/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/reports" && req.post?
  end

  # Reputation: 10 per 5 minutes per IP
  throttle("reputation/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/reputations" && req.post?
  end

  ### --- Blocklist ---

  # Block IPs in BLOCKED_IPS env var (comma-separated)
  blocklist("block-bad-ips") do |req|
    ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip)
    ips.include?(req.ip)
  end

  ### --- Response ---
  # Return 429 with a clear message
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    period = match_data[:period] || 60
    retry_after = (period - Time.now.to_i % period).to_s

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after
      },
      ["Rate limit exceeded. Try again in #{retry_after} seconds.\n"]
    ]
  end
end
