require 'optimizely'

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
    @@optimizely_client = Optimizely::Project.new(
        @datafile,
        Optimizely::EventDispatcher.new,
        Optimizely::NoOpLogger.new,
        Optimizely::NoOpErrorHandler.new,
        false
    )
    @errors.push("Invalid Optimizely client request!") unless @@optimizely_client.is_valid
    @errors.empty?
  end

  def activate_service!(visitor,experiment_key)
    begin
      @@variation = @optimizely_client.activate(
          experiment_key,
          visitor.id.to_s,
          visitor.user_attributes
      )
    rescue StandardError => error
      @errors.push(error.message)
    end
    @errors.empty?
  end

  def track_service!(event_key, visitor, event_tags)
    begin
      result = @optimizely_client.track(
          event_key,
          visitor.id,
          visitor.user_attributes,
          event_tags
      )
    rescue StandardError => error
      @errors.push(error.message)
    end
    @errors.empty?
  end

  def errors
    @errors
  end

end

