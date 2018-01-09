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
set :port, 3001
enable :sessions

# On startup, read datafile and instantiate Optimizely
configure do
  URL = 'https://cdn.optimizely.com/json'.freeze
  set logging: Logger::DEBUG, project_id: '9110532340',
   experiment_key: 'My_ruby_experiment', event_key: 'exp2_event'
  response = RestClient.get "#{URL}/" + "#{settings.project_id}.json"
  set optimizely_service: OptimizelyService.new(response.body)
end

before do
  @optimizely_service = settings.optimizely_service
  @experiment_key = settings.experiment_key
  @event_key = settings.event_key
  content_type :json
  halt 401, { error: 'Unauthorized' }.to_json unless params[:user_id]
end

def authenticate_user!
  content_type :json
  @user_id = session['user_id']
  halt 401, { error: 'Unauthorized' }.to_json unless @user_id || (@user_id == params[:user_id])
end

get '/' do
  content_type :json
  { user_name: 'value1', password: 'value2' }.to_json
end

post '/login' do
  content_type :json
  if @optimizely_service.instantiate!
    variation, succeeded = @optimizely_service.activate_service!(
     params[:user_id],
     @experiment_key
    )
    if succeeded
      session['user_id'] = params[:user_id]
      if variation == 'sort_by_price'
        {variation: variation, rollout: false, products: Product::PRODUCTS.sort_by { |hsh| hsh[:price] }}.to_json
      elsif variation == 'sort_by_name'
        {variation: variation, rollout: false, products: Product::PRODUCTS.sort_by { |hsh| hsh[:name] }}.to_json
      else
        {variation: variation, rollout: false, products: Product::PRODUCTS}.to_json
      end
    else
      { error: @optimizely_service.errors}.to_json
    end
  else
    { error: @optimizely_service.errors}.to_json
  end
end

post '/track' do
  # Calls before_action get_visitor from Application Controller to get visitor
  # Calls before_action get_project_configuration from Private methods to get config object
  # Calls before_action optimizely_client_present? to check optimizely_client object exists
  # Calls before_action get_product to get selected project
  # Calls optmizely client's track method from OptimizelyService class
  content_type :json
  authenticate_user!
  @product = Product.find(params[:product_id].to_i)
  halt 401, { error: @optimizely_service.errors}.to_json unless @product
  if @optimizely_service.track_service!(
   @event_key,
   @user_id,
   Product::Event_Tags
  )
    Cart.create_record(@product[:id])
    { success: "Successfully Purchased item #{@product[:name]} for visitor #{@user_id}!"}.to_json
  else
    { error: @optimizely_service.errors}.to_json
  end
end
