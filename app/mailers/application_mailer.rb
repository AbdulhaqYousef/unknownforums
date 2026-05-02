class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "UnknownForums <noreply@unknownforums.fun>")
  layout "mailer"
end
