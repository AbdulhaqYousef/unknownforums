module UserLeveling
  extend ActiveSupport::Concern

  XP_PER_LEVEL = 250
  XP_PER_POST = 15

  def level
    override = level_override if has_attribute?(:level_override)
    return override if override.present? && override.positive?

    1 + (xp_value / self.class::XP_PER_LEVEL)
  end

  def level_progress_percent
    return 100 if has_attribute?(:level_override) && level_override.present? && level_override.positive?

    ((xp_value % self.class::XP_PER_LEVEL).to_f / self.class::XP_PER_LEVEL * 100).round
  end

  def xp_to_next_level
    return 0 if has_attribute?(:level_override) && level_override.present? && level_override.positive?

    self.class::XP_PER_LEVEL - (xp_value % self.class::XP_PER_LEVEL)
  end

  def award_post_xp!
    return unless has_attribute?(:experience_points)

    increment!(:experience_points, self.class::XP_PER_POST)
  end

  def xp_value
    has_attribute?(:experience_points) ? experience_points.to_i : 0
  end

  def level_rank
    case level
    when 1..4 then "Newcomer"
    when 5..14 then "Member"
    when 15..29 then "Regular"
    when 30..49 then "Veteran"
    when 50..74 then "Expert"
    when 75..99 then "Elite"
    when 100..149 then "Master"
    else "Legend"
    end
  end
end
