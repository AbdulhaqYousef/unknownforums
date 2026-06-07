# frozen_string_literal: true

module ForumReadable
  extend ActiveSupport::Concern

  included do
    scope :publicly_readable, -> {
      if table_name == "categories"
        where(public_read: true)
      else
        joins(:category).where(categories: { public_read: true }, subforums: { public_read: true })
      end
    }
  end

  def publicly_readable?
    if is_a?(Category)
      public_read?
    else
      category.public_read? && public_read?
    end
  end

  def members_only?
    !publicly_readable?
  end

  def readable_by?(user)
    return true if user&.admin?
    return true if user&.can_moderate_category?(self.is_a?(Category) ? self : category)

    if is_a?(Category)
      return true if public_read?
    else
      return false unless category.readable_by?(user)
      return true if public_read?
    end

    user.present?
  end

  class_methods do
    def readable_by(user)
      return all if user&.admin?
      return all if user.present?

      publicly_readable
    end
  end
end
