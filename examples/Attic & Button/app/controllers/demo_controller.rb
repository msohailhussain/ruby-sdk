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
class DemoController < ApplicationController
  
  before_action :validate_login!, only: :create
  before_action :authenticate_user!, except: [:new, :create, :logout]
  before_action :session_exists?, only: [:new]
  # before_action :optimizely_client_present?, only: [:create]
  before_action :initialize_optimizely_service!, only:[:create, :buy, :purchases]
  before_action :get_product, only: [:buy]
  
  def new1
    # Finds Project ID if stored in session.
    # Returns new config object if Project ID not found
    #   else Finds config by Project ID stored in session
    #   Initializes OptimizelyService and generates Optimizely client object
    # Returns config

    return (@config = Config.new) unless session[:config_project_id].present?

    @config = Config.find_by_project_id(session[:config_project_id]) || Config.new
    @config = get_config unless @config.new_record?
  end

  def create
    # Calls before_action validate_config! from Private methods to
    #   get or create config object by Project ID given in params
    # Calls API https://cdn.optimizely.com/json
    # Initializes OptimizelyService class with API response body as datafile
    # instantiate! method initializes Optimizely::Project with datafile
    # Updates config by permitted params
    # If config is updated by params then store Project ID in session else return error.
    
    begin
      if @optimizely_service.instantiate!
        @variation, succeeded = @optimizely_service.activate_service!(
         params[:user_id],
         OPTIMIZELY_CONFIG['experiment_key']
        )
        if succeeded
          if @variation
            session[:user_id] = params[:user_id]
            session[:variation] = @variation
            redirect_to shop_path(user_id: session[:user_id])
          else
            flash.now[:error] = "Failed to create variation using Experiment key: #{OPTIMIZELY_CONFIG['experiment_key']}!"
            render 'new'
          end
        else
          flash[:error] = @optimizely_service.errors
          render 'new'
        end
      else
        flash[:error] = @optimizely_service.errors
        render 'new'
      end
    rescue StandardError => error
      flash.now[:error] = "Failed to load datafile using Project ID: #{OPTIMIZELY_CONFIG['project_id']} (#{error})!"
      render 'new'
    end
  end
  
  def shop
    # Calls before_action get_visitor from Application Controller to get visitor
    # Calls before_action get_project_configuration from Private methods to get config object
    # Calls before_action optimizely_client_present? to check optimizely_client object exists
    # Lists all products from Product model
    # Calls optimizely client activate method to create variation(Static object) in OptimizelyService class
  
    @variation = session[:variation]
    if @variation == 'sort_by_price'
      @products = Product::PRODUCTS.sort_by { |hsh| hsh[:price] }
    elsif @variation == 'sort_by_name'
      @products = Product::PRODUCTS.sort_by { |hsh| hsh[:name] }
    else
      @products = Product::PRODUCTS
    end
  end

  def buy
    # Calls before_action get_visitor from Application Controller to get visitor
    # Calls before_action get_project_configuration from Private methods to get config object
    # Calls before_action optimizely_client_present? to check optimizely_client object exists
    # Calls before_action get_product to get selected project
    # Calls optmizely client's track method from OptimizelyService class
    if @optimizely_service.track_service!(
     OPTIMIZELY_CONFIG['event_key'],
     session[:user_id],
      Product::Event_Tags
    )
      Purchase.create_record(@product[:id])
      flash.now[:success] = "Successfully Purchased item #{@product[:name]} for visitor #{session[:user_id]}!"
    else
      flash.now[:error] = @optimizely_service.errors
    end
  end

  def purchases
    @enabled, succeeded = @optimizely_service.is_feature_enabled_service!(
      OPTIMIZELY_CONFIG['feature_flag_key'],
      session[:user_id]
    )
    if succeeded
      @purchases = Purchase.all_purchases
    else
      flash[:error] = @optimizely_service.errors
      redirect_to shop_path(user_id: session[:user_id])
    end
  end
  
  def log_messages
    # Returns all log messages
    @logs = LogMessage.all_logs
  end

  def delete_messages
    LogMessage.delete_all_logs
    redirect_to messages_path
    flash[:success] = 'log messages deleted successfully.'
  end
  
  def delete_purchases
    Purchase.delete_all_purchases
    redirect_to checkout_path
    flash[:success] = 'Purchase record deleted successfully.'
  end
  
  def checkout_cart
    Purchase.delete_all_purchases
    redirect_to shop_path(user_id: @user_id)
  end
  
  def logout
    session.delete(:user_id)
    session.delete(:variation)
    redirect_to new_demo_path
  end
  
  private
  
  def initialize_optimizely_service!
    @optimizely_service = OptimizelyService.new(DATAFILE)
  end
  
  def validate_login!
    unless params[:user_id].present? && params[:password].present?
      flash[:error] = "User ID or Password can't be blank!"
      redirect_to new_demo_path
    end
    
    unless OPTIMIZELY_CONFIG['experiment_key'].present?
      flash[:error] = "Experiment key can't be blank! add in optimizely_config.yml!"
      redirect_to new_demo_path
    end
  end

  def authenticate_user!
    unless session[:user_id] && session[:user_id] == params[:user_id]
      flash[:error] = "Unauthorized user! #{params[:user_id]}"
      redirect_to new_demo_path
    end
    @user_id = session[:user_id]
  end
  
  def session_exists?
    redirect_to shop_path(user_id: session[:user_id]) if session[:user_id]
  end
  
  def get_product
    @product = Product.find(params[:product_id].to_i)
  end
end
