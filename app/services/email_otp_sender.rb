require "erb"
require "resend"

class EmailOtpSender
  class DeliveryDisabled < StandardError; end
  class DeliveryFailed < StandardError; end

  def self.call(user:, purpose:)
    api_key = ENV["RESEND_API_KEY"].presence
    raise DeliveryDisabled, "RESEND_API_KEY is not configured" unless api_key

    code = user.generate_email_otp!(purpose: purpose)
    Resend.api_key = api_key
    Resend::Emails.send(
      {
        from: ENV.fetch("MAIL_FROM", "UnknownForums <noreply@unknownforums.fun>"),
        to: [ user.email ],
        subject: subject_for(purpose),
        html: html_body(user, code, purpose),
        text: text_body(user, code, purpose)
      }
    )
  rescue DeliveryDisabled
    raise
  rescue => error
    Rails.logger.error("Email OTP delivery failed for user_id=#{user.id} purpose=#{purpose}: #{error.class}: #{error.message}. #{diagnostics}")
    raise DeliveryFailed, "#{error.class}: #{error.message}"
  end

  def self.diagnostics
    "resend_api_key_present=#{ENV['RESEND_API_KEY'].present?} mail_from=#{ENV.fetch('MAIL_FROM', 'UnknownForums <noreply@unknownforums.fun>').inspect}"
  end

  def self.subject_for(purpose)
    purpose.to_s == "registration" ? "Verify your UnknownForums email" : "Your UnknownForums login code"
  end

  def self.html_body(user, code, purpose)
    action = purpose.to_s == "registration" ? "verify your email and finish creating your UnknownForums account" : "finish logging in to your UnknownForums account"
    <<~HTML
      <div style="background:#1b1b1b;color:#cfcfcf;font-family:Verdana,Arial,sans-serif;font-size:13px;line-height:1.6;padding:24px;">
        <div style="max-width:520px;margin:0 auto;background:#242424;border:1px solid #444;">
          <div style="background:#303030;border-bottom:1px solid #444;color:#e0e0e0;font-weight:bold;padding:10px 14px;">UnknownForums</div>
          <div style="padding:16px;">
            <p>Hello <strong>#{ERB::Util.html_escape(user.username)}</strong>,</p>
            <p>Use this code to #{action}.</p>
            <div style="background:#111;border:1px solid #555;color:#f0c060;font-size:28px;font-weight:bold;letter-spacing:6px;padding:12px;text-align:center;">#{code}</div>
            <p style="color:#888;font-size:11px;">This code expires in #{(User::EMAIL_OTP_EXPIRATION / 60).to_i} minutes. If you did not request this, you can ignore this email.</p>
          </div>
        </div>
      </div>
    HTML
  end

  def self.text_body(user, code, purpose)
    action = purpose.to_s == "registration" ? "verify your email and finish creating your UnknownForums account" : "finish logging in to your UnknownForums account"
    <<~TEXT
      Hello #{user.username},

      Use this code to #{action}.

      Code: #{code}

      This code expires in #{(User::EMAIL_OTP_EXPIRATION / 60).to_i} minutes. If you did not request this, you can ignore this email.
    TEXT
  end
end
