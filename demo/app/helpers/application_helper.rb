module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type
      when "success"
        "alert-success"   # Green
      when "error"
        "alert-danger"    # Red
      when "alert"
        "alert-warning"   # Yellow
      when "notice"
        "alert-info"      # Blue
      else
        flash_type.to_s
    end
  end

  def assign_active_class path
    current_page?(path) ? 'active' : ''
  end

  def get_level_class type
    if type == LogMessage::LOGGER_LEVELS[:DEBUG] || type == LogMessage::LOGGER_LEVELS[:INFO]
      "table-info"
    elsif type == LogMessage::LOGGER_LEVELS[:WARN]
      "table-warning"
    elsif type == LogMessage::LOGGER_LEVELS[:ERROR] || type == LogMessage::LOGGER_LEVELS[:FATAL]
      "table-danger"
    else
      ""
    end
  end
end
