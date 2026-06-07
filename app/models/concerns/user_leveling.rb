module UserLeveling
  extend ActiveSupport::Concern

  XP_PER_LEVEL = 100
  XP_PER_POST = 15

  def level
    override = level_override
    return override if override.present? && override.positive?

    1 + (experience_points / self.class::XP_PER_LEVEL)
  end

  def level_progress_percent
    return 100 if level_override.present? && level_override.positive?

    ((experience_points % self.class::XP_PER_LEVEL).to_f / self.class::XP_PER_LEVEL * 100).round
  end

  def xp_to_next_level
    return 0 if level_override.present? && level_override.positive?

    self.class::XP_PER_LEVEL - (experience_points % self.class::XP_PER_LEVEL)
  end

  def award_post_xp!
    increment!(:experience_points, self.class::XP_PER_POST)
  end
end
