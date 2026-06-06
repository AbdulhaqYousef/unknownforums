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

  EXTENSION_MIME_MAP = {
    ".7z" => "application/x-7z-compressed",
    ".apk" => "application/vnd.android.package-archive",
    ".avi" => "video/x-msvideo",
    ".bat" => "application/x-msdownload",
    ".bin" => "application/octet-stream",
    ".bz2" => "application/x-bzip2",
    ".cfg" => "text/plain",
    ".conf" => "text/plain",
    ".csv" => "text/csv",
    ".dat" => "application/octet-stream",
    ".dll" => "application/x-msdownload",
    ".doc" => "application/msword",
    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".exe" => "application/x-msdownload",
    ".flac" => "audio/flac",
    ".gz" => "application/gzip",
    ".ini" => "text/plain",
    ".iso" => "application/x-iso9660-image",
    ".jar" => "application/java-archive",
    ".json" => "application/json",
    ".log" => "text/plain",
    ".m4a" => "audio/mp4",
    ".md" => "text/markdown",
    ".mkv" => "video/x-matroska",
    ".mcpack" => "application/octet-stream",
    ".mod" => "application/octet-stream",
    ".mp3" => "audio/mpeg",
    ".msi" => "application/x-msdownload",
    ".nbt" => "application/octet-stream",
    ".ogg" => "audio/ogg",
    ".ppt" => "application/vnd.ms-powerpoint",
    ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".rar" => "application/vnd.rar",
    ".tar" => "application/x-tar",
    ".txt" => "text/plain",
    ".wav" => "audio/wav",
    ".wma" => "audio/x-ms-wma",
    ".xls" => "application/vnd.ms-excel",
    ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xml" => "application/xml",
    ".yaml" => "text/yaml",
    ".yml" => "text/yaml",
    ".zip" => "application/zip"
  }.freeze

  class << self
    def group_keys
      GROUPS.keys
    end

    def for_attachable(attachable)
      rules_for_attachable(attachable)[:types]
    end

    def accept_for_attachable(attachable)
      rules_for_attachable(attachable)[:accept]
    end

    def summary_for_attachable(attachable)
      rules_for_attachable(attachable)[:summary]
    end

    def rules_for_attachable(attachable)
      case attachable
      when Post
        rules_for_thread(attachable.thread)
      when ForumThread
        rules_for_thread(attachable)
      when PrivateMessage
        global_rules
      else
        global_rules
      end
    end

    def rules_for_subforum(subforum)
      return global_rules unless subforum

      build_rules(effective_policy_for_subforum(subforum))
    end

    def effective_policy_for_subforum(subforum)
      own = parse_policy(subforum.allowed_file_types)
      if subforum.allowed_file_types.blank?
        return effective_policy_for_category(subforum.category)
      end

      if own[:inherit_groups]
        merge_policies(effective_policy_for_category(subforum.category), own)
      else
        own
      end
    end

    def effective_policy_for_category(category)
      return global_policy unless category

      own = parse_policy(category.allowed_file_types)
      if category.allowed_file_types.blank?
        return global_policy
      end

      if own[:inherit_groups]
        merge_policies(global_policy, own)
      else
        own
      end
    end

    def merge_policies(base, extra)
      {
        groups: base[:groups],
        inherit_groups: false,
        custom: base[:custom] + extra[:custom]
      }
    end

    def inherit_groups_only?(raw)
      policy = parse_policy(raw)
      policy[:inherit_groups] && !policy[:groups]
    end

    def rules_for_thread(thread)
      return global_rules unless thread&.subforum

      rules_for_subforum(thread.subforum)
    end

    def global_rules
      build_rules(global_policy)
    end

    def global_policy
      parse_policy(SiteSetting.allowed_file_type_groups_raw)
    end

    def global_types
      global_rules[:types]
    end

    def parse_policy(raw)
      return { groups: nil, custom: [], inherit_groups: false } if raw.blank?

      parsed = JSON.parse(raw)
      if parsed.is_a?(Hash)
        groups = if parsed.key?("groups")
          Array(parsed["groups"]).map(&:to_s).select { |key| GROUPS.key?(key) }
        end
        custom = parse_custom_entries(parsed["custom"])
        inherit_groups = parsed["inherit_groups"] == true
        { groups: groups, custom: custom, inherit_groups: inherit_groups }
      elsif parsed.is_a?(Array)
        groups = parsed.map(&:to_s).select { |key| GROUPS.key?(key) }.presence
        { groups: groups, custom: [], inherit_groups: false }
      else
        { groups: nil, custom: [], inherit_groups: false }
      end
    rescue JSON::ParserError
      { groups: nil, custom: [], inherit_groups: false }
    end

    def resolve_policy(raw)
      return nil if raw.blank?

      policy = parse_policy(raw)
      return policy unless policy[:groups].nil? && policy[:custom].empty?

      nil
    end

    def parse_groups(raw)
      parse_policy(raw)[:groups]
    end

    def expand_groups(group_keys)
      group_keys.flat_map { |key| GROUPS.fetch(key)[:types] }.uniq & Attachment::DEFAULT_ALLOWED_TYPES
    end

    def selected_groups_for(raw)
      parse_groups(raw) || group_keys
    end

    def custom_text_for(raw)
      parse_policy(raw)[:custom].map { |entry| entry[:input] }.join("\n")
    end

    def parse_custom_input(text)
      text.to_s.lines.filter_map do |line|
        parse_custom_line(line)
      end
    end

    def parse_custom_entries(value)
      case value
      when Array
        value.filter_map { |line| parse_custom_line(line.to_s) }
      when String
        parse_custom_input(value)
      else
        []
      end
    end

    def parse_custom_line(line)
      cleaned = line.to_s.strip
      return nil if cleaned.blank?
      return nil if cleaned.start_with?("#")

      if cleaned.start_with?(".")
        ext = cleaned.downcase
        { input: cleaned, ext: ext, mime: mime_for_extension(ext) }
      elsif cleaned.include?("/")
        { input: cleaned, ext: nil, mime: cleaned }
      else
        ext = ".#{cleaned.delete_prefix('.').downcase}"
        { input: cleaned, ext: ext, mime: mime_for_extension(ext) }
      end
    end

    def mime_for_extension(ext)
      EXTENSION_MIME_MAP[ext.downcase] || "application/octet-stream"
    end

    def build_rules(policy)
      group_types = if policy[:groups].nil?
        Attachment::DEFAULT_ALLOWED_TYPES.dup
      elsif policy[:groups].empty?
        []
      else
        expand_groups(policy[:groups])
      end
      custom_types = policy[:custom].map { |entry| entry[:mime] }
      types = (group_types + custom_types).uniq
      accept = accept_list(types, policy[:custom])
      summary = human_summary(types, policy[:custom])

      { types: types, accept: accept, summary: summary, policy: policy }
    end

    def accept_list(types, custom_entries)
      (types + custom_entries.filter_map { |entry| entry[:ext] }).uniq.join(",")
    end

    def accept_attribute(types)
      types.join(",")
    end

    def human_summary(types, custom_entries = [])
      labels = GROUPS.filter_map do |key, meta|
        meta[:label].split(" (").first if (meta[:types] & types).any?
      end

      custom_labels = custom_entries.map { |entry| entry[:ext] || entry[:mime] }
      parts = labels + custom_labels
      parts.presence&.join(" · ") || "files"
    end

    def store_inherit_custom(custom:)
      custom_entries = parse_custom_input(custom)
      return nil if custom_entries.empty?

      {
        inherit_groups: true,
        custom: custom_entries.map { |entry| entry[:input] }
      }.to_json
    end

    def store_record_policy(groups:, custom: nil, inherit_groups: false)
      return store_inherit_custom(custom: custom) if inherit_groups

      group_keys = Array(groups).map(&:to_s).select { |key| GROUPS.key?(key) }
      custom_entries = parse_custom_input(custom)
      payload = {
        "inherit_groups" => false,
        "groups" => group_keys
      }
      payload["custom"] = custom_entries.map { |entry| entry[:input] } if custom_entries.any?
      payload.to_json
    end

    def store_policy(groups:, custom: nil)
      group_keys = Array(groups).map(&:to_s).select { |key| GROUPS.key?(key) }
      custom_entries = parse_custom_input(custom)
      payload = { "groups" => group_keys }
      payload["custom"] = custom_entries.map { |entry| entry[:input] } if custom_entries.any?
      payload.to_json
    end

    def store_groups(group_keys)
      store_policy(groups: group_keys)
    end

    def group_labels(group_keys)
      Array(group_keys).filter_map { |key| GROUPS[key]&.dig(:label)&.split(" (")&.first }
    end

    def policy_label(policy)
      parts = []
      if policy[:groups].nil?
        parts << "All built-in groups"
      elsif policy[:groups].empty?
        parts << "No built-in groups"
      else
        parts << "Groups: #{group_labels(policy[:groups]).join(', ')}"
      end
      custom = policy[:custom].map { |entry| entry[:ext] || entry[:mime] }
      parts << "Extra: #{custom.join(', ')}" if custom.any?
      parts.join(" · ")
    end

    def global_policy_label
      policy_label(global_policy)
    end

    def admin_policy_label(record)
      unless record.class.column_names.include?("allowed_file_types")
        return "Site default (migration pending)"
      end

      case record
      when Category
        if record.allowed_file_types.blank?
          "Site default"
        elsif inherit_groups_only?(record.allowed_file_types)
          label = "Site default"
          custom = parse_policy(record.allowed_file_types)[:custom]
          label += " + Extra: #{custom.map { |e| e[:ext] || e[:mime] }.join(', ')}" if custom.any?
          label
        else
          policy_label(parse_policy(record.allowed_file_types))
        end
      when Subforum
        if record.allowed_file_types.blank?
          "Category default"
        elsif inherit_groups_only?(record.allowed_file_types)
          label = "Category default"
          custom = parse_policy(record.allowed_file_types)[:custom]
          label += " + Extra: #{custom.map { |e| e[:ext] || e[:mime] }.join(', ')}" if custom.any?
          label
        else
          policy_label(parse_policy(record.allowed_file_types))
        end
      else
        global_policy_label
      end
    end

    def extension_allowed?(filename, custom_entries)
      ext = File.extname(filename.to_s).downcase
      return false if ext.blank?

      custom_entries.any? { |entry| entry[:ext] == ext }
    end

    def type_allowed?(content_type, filename, rules)
      types = rules[:types]
      return true if types.include?(content_type)
      return false if filename.blank?

      custom_entries = rules[:policy][:custom]
      return true if extension_allowed?(filename, custom_entries) &&
        content_type.in?(%w[application/octet-stream application/x-msdownload])

      false
    end
  end
end
