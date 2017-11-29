class LogMessage < ActiveHash::Base
  @@data = []

  fields :type, :message
  field  :created_at, default: Time.now

  LOGGER_LEVELS = {DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, FATAL: 4, UNKNOWN: 5}.freeze

  def self.create_record(type, message)
    @@data << create(type: type, message: message, created_at: Time.now)
  end

  def self.all_logs
    @@data.reverse
  end

  def self.delete_all_logs
    delete_all
    @@data = []
  end
end
