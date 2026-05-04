class UserMailer < ApplicationMailer
  def email_otp(user, code, purpose)
    @user = user
    @code = code
    @purpose = purpose.to_s
    @expires_in_minutes = (User::EMAIL_OTP_EXPIRATION / 60).to_i

    subject = @purpose == "registration" ? "Verify your UnknownForums email" : "Your UnknownForums login code"
    mail(to: @user.email, subject: subject)
  end

  def thread_reply_notification(user, post)
    @user   = user
    @post   = post
    @thread = post.thread
    @author = post.user
    mail(to: @user.email, subject: "New reply in \"#{@thread.title.truncate(60)}\"")
  end

  def mention_notification(user, post)
    @user   = user
    @post   = post
    @thread = post.thread
    @author = post.user
    mail(to: @user.email, subject: "#{@author.username} mentioned you in \"#{@thread.title.truncate(60)}\"")
  end

  def password_reset(user, token)
    @user  = user
    @token = token
    @reset_url = edit_password_reset_url(@token, host: Rails.application.config.action_mailer.default_url_options[:host])
    mail(to: @user.email, subject: "Reset your password")
  end

  def warning_notification(user, warning)
    @user    = user
    @warning = warning
    mail(to: @user.email, subject: "You have received a warning on UnknownForums")
  end
end
