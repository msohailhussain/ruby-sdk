#
#    Copyright 2017, Optimizely and contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'sinatra'
require 'json'
require 'rest-client'
require 'byebug'

require_relative './optimizely_service'
require_relative './product'

set :bind, '0.0.0.0'
set :port, 3000

# On startup, read datafile and instantiate Optimizely
configure do
  URL = 'https://cdn.optimizely.com/json'.freeze
  set logging: Logger::DEBUG, project_id: '9110532340', experiment_key: 'experimentKey'
  response = RestClient.get "#{URL}/" + "#{settings.project_id}.json"
  set optimizely_service: OptimizelyService.new(response.body)
end

def authenticate_user!
  unless params[:user_id]
    halt 401, { error: 'Unauthorized' }.to_json
  end
end

get '/' do
  content_type :json
  { user_name: 'value1', password: 'value2' }.to_json
end

post '/login' do
  content_type :json
  authenticate_user!
  if settings.optimizely_service.instantiate!
    variation, succeeded = settings.optimizely_service.activate_service!(
     params[:user_id],
     settings.experiment_key
    )
    if succeeded
      if variation == 'sort_by_price'
        {variation: variation, rollout: false, products: Product::PRODUCTS.sort_by { |hsh| hsh[:price] }}.to_json
      elsif variation == 'sort_by_name'
        {variation: variation, rollout: false, products: Product::PRODUCTS.sort_by { |hsh| hsh[:name] }}.to_json
      else
        {variation: variation, rollout: false, products: Product::PRODUCTS}.to_json
      end
    else
      { error: settings.optimizely_service.errors}.to_json
    end
  else
    { error: settings.optimizely_service.errors}.to_json
  end
end

post '/track' do
  content_type :json
  authenticate_user!
  event_key = settings.event_key
  user_id = @payload.fetch('user_id')
  # attributes = @payload.fetch('attributes') { Hash.new }
  # event_tags = @payload.fetch('event_tags') { Hash.new }
  #
  # result = @optly.track(event_key, user_id, attributes, event_tags)
  # {:result => result, :user_profiles => user_profiles}.to_json
end
