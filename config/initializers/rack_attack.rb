# frozen_string_literal: true

class Rack::Attack
  ### --- Cache store ---
  # Keep rate-limit state isolated from the app database/cache tables.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### --- Safelist ---
  # Allow all requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end if Rails.env.development?

  safelist("allow-static-and-health") do |req|
    req.path.start_with?("/assets/", "/favis/", "/up") || req.path.in?(%w[/robots.txt /sitemap.xml])
  end

  def self.write_request?(req)
    req.post? || req.patch? || req.put? || req.delete?
  end

  def self.normalized_ip(req)
    req.ip.to_s
  end

  ### --- Throttles ---

  # Generous browsing limit so real users don't feel rate-limited.
  throttle("req/ip", limit: 1_500, period: 5.minutes) do |req|
    normalized_ip(req)
  end

  throttle("writes/ip", limit: 120, period: 1.minute) do |req|
    normalized_ip(req) if write_request?(req)
  end

  throttle("noise/ip", limit: 20, period: 1.minute) do |req|
    normalized_ip(req) if req.path.match?(%r{\A/(wp-admin|wp-login|xmlrpc\.php|phpmyadmin|\.env|vendor/phpunit|server-status)})
  end

  # Login: forgiving for typos, strict against brute force.
  throttle("logins/ip/burst", limit: 10, period: 1.minute) do |req|
    normalized_ip(req) if req.path == "/login" && req.post?
  end

  throttle("logins/ip/sustained", limit: 30, period: 1.hour) do |req|
    normalized_ip(req) if req.path == "/login" && req.post?
  end

  # Per-username login protection.
  throttle("logins/username", limit: 10, period: 15.minutes) do |req|
    if req.path == "/login" && req.post?
      req.params.dig("username")&.to_s&.downcase&.strip.presence
    end
  end

  # Registration: allow a few real signups, block bursts/farms.
  throttle("registrations/ip/hour", limit: 5, period: 1.hour) do |req|
    normalized_ip(req) if req.path == "/register" && req.post?
  end

  throttle("registrations/ip/day", limit: 12, period: 1.day) do |req|
    normalized_ip(req) if req.path == "/register" && req.post?
  end

  # Password reset requests: strict to prevent email flooding.
  throttle("password_resets/ip", limit: 5, period: 15.minutes) do |req|
    normalized_ip(req) if req.path == "/password_resets" && req.post?
  end

  throttle("email-otp/ip", limit: 10, period: 10.minutes) do |req|
    normalized_ip(req) if req.path.start_with?("/email-otp") && req.post?
  end

  throttle("email-otp-resend/ip", limit: 5, period: 1.hour) do |req|
    normalized_ip(req) if req.path == "/email-otp/resend" && req.post?
  end

  # Posting: enough for active users, low enough to stop spam floods.
  throttle("posts/ip", limit: 20, period: 5.minutes) do |req|
    normalized_ip(req) if req.path.match?(%r{/threads/.*/posts}) && req.post?
  end

  # Thread creation.
  throttle("threads/ip", limit: 10, period: 15.minutes) do |req|
    normalized_ip(req) if req.path.match?(%r{/subforums/.*/threads}) && req.post?
  end

  # Private messages.
  throttle("messages/ip", limit: 20, period: 5.minutes) do |req|
    normalized_ip(req) if req.path == "/messages" && req.post?
  end

  # File uploads.
  throttle("uploads/ip", limit: 12, period: 10.minutes) do |req|
    normalized_ip(req) if req.path.match?(%r{/attachments}) && req.post?
  end

  throttle("multipart_uploads/ip", limit: 15_000, period: 24.hours) do |req|
    normalized_ip(req) if req.path.start_with?("/direct_multipart_uploads") && req.post?
  end

  # Reports.
  throttle("reports/ip", limit: 10, period: 15.minutes) do |req|
    normalized_ip(req) if req.path == "/reports" && req.post?
  end

  # Reputation.
  throttle("reputation/ip", limit: 30, period: 5.minutes) do |req|
    normalized_ip(req) if req.path == "/reputations" && req.post?
  end

  # User search / mention autocomplete — prevent username enumeration scraping.
  throttle("user_search/ip", limit: 60, period: 1.minute) do |req|
    normalized_ip(req) if req.path == "/users/search" && req.get?
  end

  ### --- Blocklist ---

  # Block IPs in BLOCKED_IPS env var (comma-separated)
  blocklist("block-bad-ips") do |req|
    ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip)
    ips.include?(req.ip)
  end

  blocklist("block-no-user-agent") do |req|
    req.user_agent.to_s.blank? && !req.path.start_with?("/up") && !req.path.in?(%w[/robots.txt /sitemap.xml])
  end

  ### --- Response ---
  ### --- Attack event logging ---
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req     = payload[:request]
    matched = req.env["rack.attack.matched"].to_s
    begin
      AttackEvent.log(req, matched)
      if AttackEvent.spike?
        Rails.logger.warn("[ATTACK WARNING] Rate-limit spike detected — #{matched} from #{req.ip}")
      end
    rescue => e
      Rails.logger.error("AttackEvent logging failed: #{e.message}")
    end
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    begin
      AttackEvent.log(req, "blocklist:#{req.env['rack.attack.matched']}")
    rescue => e
      Rails.logger.error("AttackEvent blocklist logging failed: #{e.message}")
    end
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    matched = request.env["rack.attack.matched"].to_s
    period = match_data[:period] || 60
    limit = match_data[:limit] || 0
    retry_after = (period - Time.now.to_i % period).to_s
    reset_at = (Time.now.to_i + retry_after.to_i).to_s
    message = if matched.include?("login")
      "Too many login attempts. Please wait a moment before trying again."
    elsif matched.include?("registration")
      "Too many account registrations from this connection. Please try again later."
    elsif matched.include?("posts") || matched.include?("threads")
      "You're posting a little too quickly. Please slow down and try again soon."
    elsif matched.include?("messages")
      "You're sending messages a little too quickly. Please wait a moment."
    else
      "You're moving a little too fast. Please wait a moment and try again."
    end

    headers = {
      "Retry-After" => retry_after,
      "RateLimit-Limit" => limit.to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => reset_at,
      "Cache-Control" => "no-store"
    }

    if request.get_header("HTTP_ACCEPT").to_s.include?("application/json")
      [
        429,
        headers.merge("Content-Type" => "application/json"),
        [ { error: "rate_limited", message: message, retry_after: retry_after.to_i }.to_json ]
      ]
    else
      body = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <title>Slow down - UnknownForums</title>
            <style>
              body { background:#1b1b1b; color:#cfcfcf; font-family:Verdana, Arial, sans-serif; font-size:12px; margin:0; padding:24px; }
              .box { max-width:520px; margin:60px auto; background:#242424; border:1px solid #444; }
              .head { background:#303030; border-bottom:1px solid #444; padding:8px 12px; font-weight:bold; color:#e0e0e0; }
              .body { padding:16px; line-height:1.7; color:#aaa; }
              .timer { color:#f0c060; font-weight:bold; }
              a { color:#7aabde; text-decoration:none; }
            </style>
          </head>
          <body>
            <div class="box">
              <div class="head">Please slow down</div>
              <div class="body">
                <p>#{Rack::Utils.escape_html(message)}</p>
                <p>You can try again in <span class="timer">#{retry_after}</span> seconds.</p>
                <p><a href="javascript:history.back()">Go back</a></p>
              </div>
            </div>
          </body>
        </html>
      HTML

      [ 429, headers.merge("Content-Type" => "text/html; charset=utf-8"), [ body ] ]
    end
  end

  self.blocklisted_responder = lambda do |_request|
    [
      403,
      { "Content-Type" => "text/plain; charset=utf-8", "Cache-Control" => "no-store" },
      [ "Forbidden\n" ]
    ]
  end
end
