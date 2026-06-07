# frozen_string_literal: true

class LevelPerks
  SETTING_KEY = "level_perks".freeze

  DEFAULTS = {
    "custom_badge_min_level" => 5,
    "gif_avatar_min_level" => 3,
    "upload_tiers" => [
      { "min_level" => 1, "max_gb" => 0.1 },
      { "min_level" => 5, "max_gb" => 0.5 },
      { "min_level" => 10, "max_gb" => 1.0 },
      { "min_level" => 20, "max_gb" => 2.0 }
    ]
  }.freeze

  class << self
    def config
      raw = SiteSetting.get(SETTING_KEY)
      return DEFAULTS.deep_dup if raw.blank?

      parsed = JSON.parse(raw)
      DEFAULTS.deep_dup.deep_merge(parsed.stringify_keys)
    rescue JSON::ParserError
      DEFAULTS.deep_dup
    end

    def save!(custom_badge_min_level:, gif_avatar_min_level:, upload_tiers_text:)
      tiers = parse_upload_tiers_text(upload_tiers_text)
      raise ArgumentError, "Add at least one upload tier (level,max_gb per line)." if tiers.empty?

      payload = {
        "custom_badge_min_level" => custom_badge_min_level.to_i.clamp(1, 999),
        "gif_avatar_min_level" => gif_avatar_min_level.to_i.clamp(1, 999),
        "upload_tiers" => tiers
      }
      SiteSetting.set(SETTING_KEY, payload.to_json)
    end

    def custom_badge_min_level
      config["custom_badge_min_level"].to_i
    end

    def gif_avatar_min_level
      config["gif_avatar_min_level"].to_i
    end

    def upload_tiers
      Array(config["upload_tiers"]).map do |tier|
        {
          min_level: tier["min_level"].to_i,
          max_gb: tier["max_gb"].to_f,
          max_bytes: (tier["max_gb"].to_f * 1.gigabyte).to_i
        }
      end.sort_by { |tier| tier[:min_level] }
    end

    def upload_tiers_text
      upload_tiers.map { |tier| "#{tier[:min_level]},#{tier[:max_gb].to_s.sub(/\.?0+\z/, '')}" }.join("\n")
    end

    def bypass?(user)
      user&.admin?
    end

    def custom_badge_allowed?(user)
      return false unless user
      return true if bypass?(user)

      user.level >= custom_badge_min_level
    end

    def gif_avatar_allowed?(user)
      return false unless user
      return true if bypass?(user)

      user.level >= gif_avatar_min_level
    end

    def max_upload_bytes_for(user)
      return UploadLimits.global_max_bytes unless user
      return UploadLimits.global_max_bytes if bypass?(user)

      tier = applicable_upload_tier(user.level)
      bytes = tier[:max_bytes]
      [[bytes, UploadLimits::MIN_BYTES].max, UploadLimits.absolute_max_bytes].min
    end

    def upload_limit_label_for(user)
      return UploadLimits.global_label unless user

      UploadLimits.label_for(max_upload_bytes_for(user))
    end

    def unlock_message(user, feature)
      return "Sign in to unlock this feature." unless user

      required = case feature
      when :custom_badge then custom_badge_min_level
      when :gif_avatar then gif_avatar_min_level
      else 1
      end
      "Reach level #{required} to unlock this (you are level #{user.level})."
    end

    def perks_summary_for(user)
      return [] unless user

      lines = []
      lines << "Upload limit: #{upload_limit_label_for(user)}"
      lines << "GIF profile picture: #{gif_avatar_allowed?(user) ? 'Unlocked' : "Locked until level #{gif_avatar_min_level}"}"
      lines << "Custom badge GIF: #{custom_badge_allowed?(user) ? 'Unlocked' : "Locked until level #{custom_badge_min_level}"}"
      lines
    end

    private

    def applicable_upload_tier(level)
      upload_tiers.select { |tier| level >= tier[:min_level] }.last || upload_tiers.first
    end

    def parse_upload_tiers_text(text)
      Array(text.to_s.lines).filter_map do |line|
        level_text, gb_text = line.strip.split(",", 2)
        next if level_text.blank? || gb_text.blank?

        min_level = level_text.to_i
        max_gb = gb_text.to_f
        next if min_level <= 0 || max_gb <= 0

        { "min_level" => min_level, "max_gb" => max_gb }
      end.sort_by { |tier| tier["min_level"] }
    end
  end
end
