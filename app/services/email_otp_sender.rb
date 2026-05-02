class EmailOtpSender
  class DeliveryDisabled < StandardError; end

  def self.call(user:, purpose:)
    raise DeliveryDisabled, "Email delivery is not configured" unless ActionMailer::Base.perform_deliveries

    code = user.generate_email_otp!(purpose: purpose)
    UserMailer.email_otp(user, code, purpose).deliver_now
  end
end
