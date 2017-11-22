class LogMessage < ActiveHash::Base
  
  @@data = []
  
  fields :type, :message
  field  :created_at, default: Time.now
  
  LOGGER_LEVELS = {DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, FATAL: 4, UNKNOWN: 5}

  def self.create_record(type, message)
    @@data << self.create(type: type, message: message)
  end
  
  def self.all_logs
    @@data
  end
  
  def self.delete_all_logs
    self.delete_all
    @@data = []
  end
  
end
