class LogMessage < RedisOrm::Base
  
  property :type, Integer
  property :message, String
  
  timestamps
  
  LOGGER_LEVELS = {DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, FATAL: 4, UNKNOWN: 5}

end
