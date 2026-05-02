class User < ApplicationRecord
  has_secure_password

  enum :role, { user: 0, moderator: 1, admin: 2 }

  has_many :forum_threads, class_name: "ForumThread", foreign_key: :user_id, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :given_reputations, class_name: "Reputation", foreign_key: :giver_id, dependent: :destroy
  has_many :received_reputations, class_name: "Reputation", foreign_key: :receiver_id, dependent: :destroy
  has_many :sent_messages, class_name: "PrivateMessage", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "PrivateMessage", foreign_key: :recipient_id, dependent: :destroy
  has_many :reports, foreign_key: :reporter_id, dependent: :destroy

  has_one_attached :avatar

  AVATAR_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  AVATAR_MAX_SIZE = 10.megabytes
  MAX_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes
  EMAIL_OTP_EXPIRATION = 10.minutes
  EMAIL_OTP_RESEND_COOLDOWN = 60.seconds
  EMAIL_OTP_MAX_ATTEMPTS = 5

  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_\-]+\z/, message: "only allows letters, numbers, underscores and dashes" }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }
  validates :reputation, numericality: { only_integer: true }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :password_complexity, if: -> { password.present? }
  validate :avatar_format, if: -> { avatar.attached? }
  before_validation :normalize_registration_fields
  before_update :clear_email_verification_on_email_change, if: :will_save_change_to_email?
  before_update :track_previous_username, if: :will_save_change_to_username?

  def can_moderate?
    moderator? || admin?
  end

  def unread_messages_count
    received_messages.where(read: false, recipient_deleted: false).count
  end

  def post_count
    posts.where(deleted: false).count
  end

  def avatar_url
    avatar.attached? ? avatar : nil
  end

  def reputation_rank
    case reputation
    when ..0 then "Newbie"
    when 1..50 then "Member"
    when 51..200 then "Regular"
    when 201..500 then "Veteran"
    when 501..1000 then "Elite"
    else "Legend"
    end
  end

  def rep_power
    base = 1
    base += post_count / 100
    base += reputation / 250 if reputation.positive?
    [base, 10].min
  end

  def uploaded_files_count
    Attachment.where(user_id: id).count
  end

  def downloaded_files_count
    Attachment.where(user_id: id).sum(:download_count)
  end

  def locked?
    locked_until.present? && locked_until > Time.current
  end

  def register_failed_login!
    increment!(:failed_login_attempts)
    if failed_login_attempts >= MAX_LOGIN_ATTEMPTS
      update_columns(locked_until: Time.current + LOCKOUT_DURATION)
    end
  end

  def register_successful_login!(ip: nil)
    update_columns(
      failed_login_attempts: 0,
      locked_until: nil,
      last_login_at: Time.current,
      last_login_ip: ip
    )
  end

  def lockout_remaining
    return 0 unless locked?
    ((locked_until - Time.current) / 60).ceil
  end

  def email_verified?
    email_verified_at.present?
  end

  def generate_email_otp!(purpose:)
    code = format("%06d", SecureRandom.random_number(1_000_000))
    now = Time.current
    update_columns(
      email_otp_digest: BCrypt::Password.create(code),
      email_otp_sent_at: now,
      email_otp_expires_at: now + EMAIL_OTP_EXPIRATION,
      email_otp_attempts: 0,
      email_otp_purpose: purpose.to_s,
      updated_at: now
    )
    code
  end

  def verify_email_otp(code, purpose:)
    return false unless email_otp_valid_for?(purpose)
    return false if email_otp_attempts >= EMAIL_OTP_MAX_ATTEMPTS

    normalized_code = code.to_s.gsub(/\D/, "")
    if BCrypt::Password.new(email_otp_digest).is_password?(normalized_code)
      now = Time.current
      update_columns(
        email_verified_at: now,
        email_otp_digest: nil,
        email_otp_sent_at: nil,
        email_otp_expires_at: nil,
        email_otp_attempts: 0,
        email_otp_purpose: nil,
        updated_at: now
      )
      true
    else
      update_columns(email_otp_attempts: email_otp_attempts + 1, updated_at: Time.current)
      false
    end
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def email_otp_valid_for?(purpose)
    email_otp_digest.present? &&
      email_otp_purpose == purpose.to_s &&
      email_otp_expires_at.present? &&
      email_otp_expires_at.future?
  end

  def email_otp_resend_wait
    return 0 if email_otp_sent_at.blank?
    [(email_otp_sent_at + EMAIL_OTP_RESEND_COOLDOWN - Time.current).ceil, 0].max
  end

  def email_otp_resend_allowed?
    email_otp_resend_wait.zero?
  end

  private

  def normalize_registration_fields
    self.username = username.to_s.strip if username.present?
    self.email = email.to_s.strip.downcase.presence
  end

  def clear_email_verification_on_email_change
    self.email_verified_at = nil
    self.email_otp_digest = nil
    self.email_otp_sent_at = nil
    self.email_otp_expires_at = nil
    self.email_otp_attempts = 0
    self.email_otp_purpose = nil
  end

  def track_previous_username
    old_username = username_in_database
    return if old_username.blank?

    self.previous_usernames = (previous_usernames + [old_username]).uniq
  end

  def password_complexity
    return if password.blank?
    unless password.match?(/[a-z]/) && password.match?(/[A-Z]/) && password.match?(/[0-9]/)
      errors.add(:password, "must include at least one lowercase letter, one uppercase letter, and one number")
    end
    if password.downcase == username&.downcase
      errors.add(:password, "cannot be the same as your username")
    end
  end

  def avatar_format
    unless AVATAR_TYPES.include?(avatar.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, GIF, or WebP image")
    end
    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "must be smaller than 10MB")
    end
  end
end
