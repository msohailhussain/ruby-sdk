class LogMessage
  include Mongoid::Document
  field :type, type: Integer
  field :message, type: String
  field :datatime, type: DateTime, default: ->{Time.now}

  LOGGER_LEVELS = {DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, FATAL: 4, UNKNOWN: 5}

end
