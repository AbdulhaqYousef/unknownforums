module ApplicationHelper
  def avatar_image_tag(user, size:, **options)
    return unless user.avatar.attached?

    style = "width:#{size}px; height:#{size}px; object-fit:cover;"
    style = "#{style} #{options.delete(:style)}" if options[:style].present?
    image_tag rails_blob_path(user.avatar, only_path: true), options.merge(style: style)
  end

  def role_badge(user)
    klass = user.admin? ? "badge badge-pin" : "badge"
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

  def link_to_prev_page(collection, text, **opts)
    return "" if collection.current_page <= 1
    link_to text, url_for(page: collection.current_page - 1), **opts
  end

  def link_to_next_page(collection, text, **opts)
    return "" if collection.current_page >= collection.total_pages
    link_to text, url_for(page: collection.current_page + 1), **opts
  end
end
