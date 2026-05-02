class UserMailer < ApplicationMailer
  def email_otp(user, code, purpose)
    @user = user
    @code = code
    @purpose = purpose.to_s
    @expires_in_minutes = (User::EMAIL_OTP_EXPIRATION / 60).to_i

    subject = @purpose == "registration" ? "Verify your UnknownForums email" : "Your UnknownForums login code"
    mail(to: @user.email, subject: subject)
  end
end
