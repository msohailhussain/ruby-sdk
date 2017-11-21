require 'logger'
require 'optimizely'
require 'sinatra'

class OptimizelyService
  @@optimizely_client = nil
  @@variation = nil
  def initialize(datafile)
    @datafile = datafile
    @errors = []
    @optimizely_client = @@optimizely_client
    @variation = @@variation
  end

  def self.optimizely_client_present?
    @@optimizely_client.present?
  end


  def instantiate!
    @logger = SinatraLogger.new(Logger.new(STDOUT))
    @@optimizely_client = Optimizely::Project.new(
        @datafile,
        Optimizely::EventDispatcher.new,
        @logger,
        Optimizely::NoOpErrorHandler.new,
        false
    )
    @errors.push("Invalid Optimizely client request!") unless @@optimizely_client.is_valid
    @errors.empty?
  end

  def activate_service!(visitor,experiment_key)
    attributes = {'name' => visitor[:name].to_s, 'age'=> visitor[:age].to_s}
    begin
      @@variation = @optimizely_client.activate(
          experiment_key,
          visitor[:id].to_s,
          attributes
      )
    rescue StandardError => error
      @errors.push(error.message)
    end
    @errors.empty?
  end

  def track_service!(event_key, visitor, event_tags)
    attributes = {'name' => visitor[:name].to_s, 'age'=> visitor[:age].to_s}
    begin
      result = @optimizely_client.track(
          event_key,
          visitor[:id].to_s,
          attributes,
          event_tags
      )
    rescue => e
      @errors.push(e.message)
    end
    @errors.empty?
  end

  def errors
    @errors
  end

end


# Semi-hacky wrapper around Sinatra's internal logger so we actually see log messages in Jenkins
class SinatraLogger

  def initialize(logger)
    @logger = logger
  end

  def log(level=nil, message)
    @logger.info message
    LogMessage.create(type: level, message: message)
  end

end