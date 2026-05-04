Rails.application.config.session_store :cookie_store,
  key: "_forums_session",
  same_site: :strict,
  secure: Rails.env.production?,
  httponly: true,
  expire_after: 2.weeks
