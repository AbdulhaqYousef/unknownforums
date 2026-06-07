# frozen_string_literal: true

class UploadLimits
  ABSOLUTE_MAX = Attachment::MAX_SIZE
  MIN_BYTES = 1.megabyte

  class << self
    def absolute_max_bytes
      ABSOLUTE_MAX
    end

    def global_max_bytes
      raw = SiteSetting.get(SiteSetting::MAX_UPLOAD_BYTES_KEY)
      bytes = raw.to_i
      bytes = ABSOLUTE_MAX if bytes <= 0
      cap(bytes)
    end

    def set_global_max_bytes!(bytes)
      SiteSetting.set(SiteSetting::MAX_UPLOAD_BYTES_KEY, cap(bytes).to_i)
    end

    def global_label
      label_for(global_max_bytes)
    end

    def global_rules(user: nil)
      max_bytes = user ? [global_max_bytes, LevelPerks.max_upload_bytes_for(user)].min : global_max_bytes
      AllowedFileTypes.global_rules.merge(limit_payload(max_bytes))
    end

    def max_bytes_for_category(category)
      return global_max_bytes unless category
      return global_max_bytes unless upload_limit_column?(category)
      return global_max_bytes if category.max_upload_bytes.blank?

      cap(category.max_upload_bytes)
    end

    def max_bytes_for_subforum(subforum, user: nil)
      apply_user_cap(raw_max_bytes_for_subforum(subforum), user)
    end

    def max_bytes_for_thread(thread, user: nil)
      return global_max_bytes unless thread&.subforum

      max_bytes_for_subforum(thread.subforum, user: user)
    end

    def max_bytes_for_attachable(attachable, user: nil)
      forum_max = case attachable
      when Post
        max_bytes_for_thread(attachable.thread, user: user)
      when ForumThread
        max_bytes_for_thread(attachable, user: user)
      else
        global_max_bytes
      end
      apply_user_cap(forum_max, user)
    end

    def rules_for_subforum(subforum, user: nil)
      max_bytes = max_bytes_for_subforum(subforum, user: user)
      AllowedFileTypes.rules_for_subforum(subforum).merge(limit_payload(max_bytes))
    end

    def rules_for_attachable(attachable, user: nil)
      max_bytes = max_bytes_for_attachable(attachable, user: user)
      AllowedFileTypes.rules_for_attachable(attachable).merge(limit_payload(max_bytes))
    end

    def limit_payload(max_bytes)
      {
        max_bytes: max_bytes,
        max_label: label_for(max_bytes),
        multipart_threshold: multipart_threshold_bytes(max_bytes)
      }
    end

    def multipart_threshold_bytes(max_bytes = nil)
      return 0 unless Attachment.multipart_enabled?

      max = max_bytes || global_max_bytes
      [ Attachment::MULTIPART_THRESHOLD, max ].min
    end

    def label_for(bytes)
      ActiveSupport::NumberHelper.number_to_human_size(bytes)
    end

    def gb_input_value(bytes)
      return "" if bytes.nil?

      value = bytes.to_f / 1.gigabyte
      formatted = format("%.2f", value).sub(/\.?0+\z/, "")
      formatted.presence || "0"
    end

    def parse_gb_param(value)
      text = value.to_s.strip
      return nil if text.blank?

      gb = text.to_f
      return nil if gb <= 0

      cap((gb * 1.gigabyte).to_i)
    end

    def admin_label(record)
      unless upload_limit_column?(record)
        return "Site default (#{global_label})"
      end

      case record
      when Category
        if record.max_upload_bytes.blank?
          "Site default (#{global_label})"
        else
          label_for(record.max_upload_bytes)
        end
      when Subforum
        if record.max_upload_bytes.blank?
          "Category default (#{label_for(max_bytes_for_category(record.category))})"
        else
          label_for(record.max_upload_bytes)
        end
      else
        global_label
      end
    end

    private

    def raw_max_bytes_for_subforum(subforum)
      return global_max_bytes unless subforum
      return max_bytes_for_category(subforum.category) unless upload_limit_column?(subforum)
      return max_bytes_for_category(subforum.category) if subforum.max_upload_bytes.blank?

      cap(subforum.max_upload_bytes)
    end

    def apply_user_cap(forum_max, user)
      return forum_max unless user

      [forum_max, LevelPerks.max_upload_bytes_for(user)].min
    end

    def upload_limit_column?(record)
      record.class.column_names.include?("max_upload_bytes")
    end

    def cap(bytes)
      [[bytes.to_i, MIN_BYTES].max, ABSOLUTE_MAX].min
    end
  end
end
