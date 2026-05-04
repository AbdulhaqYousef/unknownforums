# frozen_string_literal: true

# Checks a password against the HaveIBeenPwned k-anonymity API.
# Only the first 5 chars of the SHA-1 hex are sent — no plaintext ever leaves the server.
class PwnedPasswordChecker
  TIMEOUT = 3 # seconds

  def self.pwned?(password)
    new(password).pwned?
  end

  def initialize(password)
    @password = password
  end

  def pwned?
    digest = Digest::SHA1.hexdigest(@password).upcase
    prefix = digest[0, 5]
    suffix = digest[5..]

    uri = URI("https://api.pwnedpasswords.com/range/#{prefix}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                               open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.path, "Add-Padding" => "true")
    end

    return false unless response.is_a?(Net::HTTPSuccess)

    response.body.each_line.any? do |line|
      hash_suffix, count = line.strip.split(":")
      hash_suffix == suffix && count.to_i > 0
    end
  rescue StandardError => e
    Rails.logger.warn("PwnedPasswordChecker failed: #{e.class}: #{e.message}")
    false # fail open — don't block registration if API is unreachable
  end
end
