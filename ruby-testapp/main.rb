require 'logger'

require 'optimizely'
require 'sinatra'
require 'json'

require_relative './user_profile_service'

set :bind, '0.0.0.0'
set :port, 3000

# On startup, read datafile and instantiate Optimizely
configure do
  set :logging, Logger::DEBUG
  datafile = File.read('datafile.json')
  set :datafile, datafile
end

post '*' do
  @payload = JSON.parse(request.body.read)
  @logger = SinatraLogger.new(logger)
  create_optly()
  pass
end

post '/activate' do
  content_type :json

  experiment_key = @payload.fetch('experiment_key')
  user_id = @payload.fetch('user_id')
  attributes = @payload.fetch('attributes') { Hash.new }

  result = @optly.activate(experiment_key, user_id, attributes)
  user_profiles = {}
  if @user_profile_service
    user_profiles = @user_profile_service.user_profiles.values
  end
  {:result => result, :user_profiles => user_profiles}.to_json
end

post '/get_variation' do
  content_type :json

  experiment_key = @payload.fetch('experiment_key')
  user_id = @payload.fetch('user_id')
  attributes = @payload.fetch('attributes') { Hash.new }

  result = @optly.get_variation(experiment_key, user_id, attributes)
  user_profiles = {}
  if @user_profile_service
    user_profiles = @user_profile_service.user_profiles.values
  end
  {:result => result, :user_profiles => user_profiles}.to_json
end

post '/track' do
  content_type :json

  event_key = @payload.fetch('event_key')
  user_id = @payload.fetch('user_id')
  attributes = @payload.fetch('attributes') { Hash.new }
  event_tags = @payload.fetch('event_tags') { Hash.new }

  result = @optly.track(event_key, user_id, attributes, event_tags)
  user_profiles = {}
  if @user_profile_service
    user_profiles = @user_profile_service.user_profiles.values
  end
  {:result => result, :user_profiles => user_profiles}.to_json
end

def create_optly()
  user_profile_service = @payload['user_profile_service']
  if user_profile_service
    user_profile_service_class = UserProfileServices.const_get(user_profile_service)
    user_profile_service = user_profile_service_class.new(@payload['user_profiles'])
    @user_profile_service = user_profile_service
  end

  @optly = Optimizely::Project.new(settings.datafile, nil, @logger, nil, nil, user_profile_service)
end

# Semi-hacky wrapper around Sinatra's internal logger so we actually see log messages in Jenkins
class SinatraLogger
  def initialize(logger)
    @logger = logger
  end

  def log(level=nil, message)
    @logger.info message
  end
end

post '/is_feature_enabled' do
  content_type :json

  feature_flag_key = @payload.fetch('feature_flag_key')
  user_id = @payload.fetch('user_id')
  attributes = @payload.fetch('attributes') { Hash.new }
  result = @optly.is_feature_enabled(feature_flag_key, user_id, attributes)
  {:result => result}.to_json
end

post '/get_feature_variable' do
  content_type :json

  feature_flag_key = @payload.fetch('feature_flag_key')
  variable_key = @payload.fetch('variable_key')
  user_id = @payload.fetch('user_id')
  attributes = @payload.fetch('attributes') { Hash.new }
  variable_type = @payload.fetch('variable_type') { Hash.new }

  result = nil
  case variable_type
  when "boolean"
    result = @optly.get_feature_variable_boolean(feature_flag_key, variable_key, user_id, attributes)
  when "double"
    result = @optly.get_feature_variable_double(feature_flag_key, variable_key, user_id, attributes)
  when "integer"
    result = @optly.get_feature_variable_integer(feature_flag_key, variable_key, user_id, attributes)
  else
    result = @optly.get_feature_variable_string(feature_flag_key, variable_key, user_id, attributes)
  end

  {:result => result}.to_json
end

