require "kramdown"

module ApplicationHelper
  def avatar_image_tag(user, size:, **options)
    return unless user.avatar.attached?

    style = "width:#{size}px; height:#{size}px; object-fit:cover;"
    style = "#{style} #{options.delete(:style)}" if options[:style].present?
    image_tag rails_blob_path(user.avatar, only_path: true), options.merge(style: style)
  end

  def role_badge(user)
    klass = if user.admin?
      "badge badge-admin"
    elsif user.moderator?
      "badge badge-moderator"
    else
      "badge"
    end
    content_tag(:span, user.role.capitalize, class: klass)
  end

  def rep_label(value)
    prefix = value.positive? ? "+" : ""
    color = value >= 0 ? "#60c060" : "#c06060"
    content_tag(:span, "#{prefix}#{value}", style: "color:#{color}; font-weight:bold;")
  end

  def reputation_description(user)
    rep = user.reputation
    case rep
    when ..(-50) then "#{user.username} can't be trusted"
    when -49..(-1) then "#{user.username} has a poor reputation"
    when 0..10 then "#{user.username} has made posts that are generally average in quality"
    when 11..50 then "#{user.username} is on a distinguished road"
    when 51..200 then "#{user.username} is a jewel in the rough"
    when 201..500 then "#{user.username} is a name known to all"
    when 501..1000 then "#{user.username} is a glorious beacon of light"
    else "#{user.username} has a reputation beyond repute"
    end
  end

  def user_level(user)
    points = user_points(user)
    level = 1
    threshold = 400
    while points >= threshold
      level += 1
      points -= threshold
      threshold = (threshold * 1.5).to_i
    end
    level
  end

  def user_points(user)
    user.post_count * 5 + user.reputation * 3 + ((Time.current - user.created_at) / 1.day).to_i
  end

  def level_progress(user)
    points = user_points(user)
    threshold = 400
    loop do
      break if points < threshold
      points -= threshold
      threshold = (threshold * 1.5).to_i
    end
    ((points.to_f / threshold) * 100).round
  end

  def points_to_next_level(user)
    points = user_points(user)
    threshold = 400
    loop do
      break if points < threshold
      points -= threshold
      threshold = (threshold * 1.5).to_i
    end
    threshold - points
  end

  def user_activity(user)
    days_since_join = [(Time.current - user.created_at) / 1.day, 1].max
    recent_posts = user.posts.where("created_at > ?", 30.days.ago).count
    activity = (recent_posts.to_f / [days_since_join, 30].min * 100).round(1)
    [activity, 100.0].min
  end

  def rep_power_dots(user)
    power = user.rep_power
    dots = ""
    power.times { dots += '<span style="display:inline-block; width:6px; height:6px; background:#60c060; margin:0 1px; border-radius:1px;"></span>' }
    dots.html_safe
  end

  def markdown_post_body(body)
    markdown = normalize_markdown_tables(normalize_markdown_fences(body.to_s))
    html = Kramdown::Document.new(markdown, hard_wrap: true, syntax_highlighter: nil).to_html
    html = html.gsub(/@([A-Za-z0-9_\-]{3,30})/) { "<strong>#{$&}</strong>" }
    sanitize html,
      tags: %w[p br strong em b i u a ul ol li blockquote code pre hr h1 h2 h3 h4 h5 h6 table thead tbody tr th td],
      attributes: %w[href title class]
  end

  def normalize_markdown_fences(markdown)
    markdown.gsub(/^```([A-Za-z0-9_-]*)\s*$/) do
      language = Regexp.last_match(1)
      language.present? ? "~~~ #{language}" : "~~~"
    end
  end

  def normalize_markdown_tables(markdown)
    lines = markdown.lines
    output = []
    i = 0
    in_fence = false

    while i < lines.length
      line = lines[i]
      in_fence = !in_fence if line.match?(/^~~~\s*/)

      if !in_fence && markdown_table_start?(lines, i)
        table_lines = [lines[i].rstrip, lines[i + 1].rstrip]
        i += 2
        while i < lines.length && lines[i].include?("|") && lines[i].strip.present?
          table_lines << lines[i].rstrip
          i += 1
        end
        output << markdown_table_html(table_lines)
        next
      end

      output << line
      i += 1
    end

    output.join
  end

  def markdown_table_start?(lines, index)
    return false unless lines[index]&.include?("|") && lines[index + 1]&.include?("|")

    separator_cells = markdown_table_cells(lines[index + 1])
    separator_cells.any? && separator_cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
  end

  def markdown_table_html(lines)
    headers = markdown_table_cells(lines[0])
    rows = lines.drop(2).map { |line| markdown_table_cells(line) }
    header_html = headers.map { |cell| "<th>#{ERB::Util.html_escape(cell)}</th>" }.join
    rows_html = rows.map do |row|
      "<tr>#{row.map { |cell| "<td>#{ERB::Util.html_escape(cell)}</td>" }.join}</tr>"
    end.join

    "<table><thead><tr>#{header_html}</tr></thead><tbody>#{rows_html}</tbody></table>\n"
  end

  def markdown_table_cells(line)
    line.to_s.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map(&:strip)
  end

  def link_to_prev_page(collection, text, **opts)
    return "" if collection.current_page <= 1
    link_to text, url_for(page: collection.current_page - 1), **opts
  end

  def link_to_next_page(collection, text, **opts)
    return "" if collection.current_page >= collection.total_pages
    link_to text, url_for(page: collection.current_page + 1), **opts
  end
end
