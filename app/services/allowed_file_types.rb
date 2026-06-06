# frozen_string_literal: true

class AllowedFileTypes
  GROUPS = {
    "images" => {
      label: "Images (JPEG, PNG, GIF, WebP)",
      types: %w[image/jpeg image/png image/gif image/webp]
    },
    "videos" => {
      label: "Videos (MP4, WebM, OGG)",
      types: %w[video/mp4 video/webm video/ogg]
    },
    "documents" => {
      label: "Documents (PDF, plain text)",
      types: %w[application/pdf text/plain]
    },
    "archives" => {
      label: "Archives (ZIP)",
      types: %w[application/zip application/x-zip-compressed]
    },
    "torrents" => {
      label: "Torrent files",
      types: %w[application/x-bittorrent]
    },
    "executables" => {
      label: "Executables / binaries (EXE, DLL, etc.)",
      types: %w[
        application/x-msdownload application/x-msdos-program
        application/x-dosexec application/octet-stream
      ]
    },
    "scripts" => {
      label: "Scripts (SH, PS1, JS)",
      types: %w[
        application/x-sh application/x-powershell
        application/javascript text/javascript
      ]
    },
    "disk_images" => {
      label: "Disk images (DMG)",
      types: %w[application/x-apple-diskimage]
    }
  }.freeze

  class << self
    def group_keys
      GROUPS.keys
    end

    def for_attachable(attachable)
      case attachable
      when Post
        for_thread(attachable.thread)
      when ForumThread
        for_thread(attachable)
      when PrivateMessage
        global_types
      else
        global_types
      end
    end

    def for_subforum(subforum)
      return global_types unless subforum

      groups = parse_groups(subforum.allowed_file_types)
      return expand_groups(groups) if groups

      groups = parse_groups(subforum.category&.allowed_file_types)
      return expand_groups(groups) if groups

      global_types
    end

    def for_thread(thread)
      return global_types unless thread&.subforum

      for_subforum(thread.subforum)
    end

    def global_types
      groups = parse_groups(SiteSetting.allowed_file_type_groups_raw)
      types = groups ? expand_groups(groups) : Attachment::DEFAULT_ALLOWED_TYPES
      types & Attachment::DEFAULT_ALLOWED_TYPES
    end

    def parse_groups(raw)
      return nil if raw.blank?

      parsed = JSON.parse(raw)
      return nil unless parsed.is_a?(Array)

      parsed.map(&:to_s).select { |key| GROUPS.key?(key) }.presence
    rescue JSON::ParserError
      nil
    end

    def expand_groups(group_keys)
      group_keys.flat_map { |key| GROUPS.fetch(key)[:types] }.uniq & Attachment::DEFAULT_ALLOWED_TYPES
    end

    def selected_groups_for(raw)
      parsed = parse_groups(raw)
      parsed || group_keys
    end

    def accept_attribute(types)
      types.join(",")
    end

    def human_summary(types)
      labels = GROUPS.filter_map do |key, meta|
        meta[:label].split(" (").first if (meta[:types] & types).any?
      end
      labels.presence&.join(" · ") || "files"
    end

    def store_groups(group_keys)
      keys = Array(group_keys).map(&:to_s).select { |key| GROUPS.key?(key) }
      return nil if keys.blank?
      return nil if keys.sort == self.group_keys.sort

      keys.to_json
    end

    def group_labels(group_keys)
      Array(group_keys).filter_map { |key| GROUPS[key]&.dig(:label)&.split(" (")&.first }
    end

    def global_policy_label
      raw = SiteSetting.allowed_file_type_groups_raw
      return "All types allowed" if raw.blank?

      "Custom: #{group_labels(parse_groups(raw)).join(', ')}"
    end

    def admin_policy_label(record)
      unless record.class.column_names.include?("allowed_file_types")
        return "Site default (migration pending)"
      end

      case record
      when Category
        if record.file_types_inherited?
          "Site default"
        else
          "Custom: #{group_labels(parse_groups(record.allowed_file_types)).join(', ')}"
        end
      when Subforum
        if record.file_types_inherited?
          "Category default"
        else
          "Custom: #{group_labels(parse_groups(record.allowed_file_types)).join(', ')}"
        end
      else
        global_policy_label
      end
    end
  end
end
