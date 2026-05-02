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

  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_\-]+\z/, message: "only allows letters, numbers, underscores and dashes" }
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }
  validates :reputation, numericality: { only_integer: true }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :password_complexity, if: -> { password.present? }
  validate :avatar_format, if: -> { avatar.attached? }
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

  private

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
