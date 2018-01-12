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
  before_action :initialize_optimizely_client!, only:[:create, :buy, :cart, :checkout_complete,:checkout_payment]
  before_action :session_exists?, only: [:new]
  before_action :get_product, only: [:buy]
  
  def create
    # Calls before_action validate_config! from Private methods to
    #   get or create config object by Project ID given in params
    # Calls API https://cdn.optimizely.com/json
    # Initializes OptimizelyService class with API response body as datafile
    # instantiate! method initializes Optimizely::Project with datafile
    # Updates config by permitted params
    # If config is updated by params then store Project ID in session else return error.
    
    begin
      @variation_key, succeeded = @optimizely_service.activate_service!(
       @current_user[:user_id],
       OPTIMIZELY_CONFIG['experiment_key']
      )
      if succeeded
        if @variation_key
          session[:current_user] = @current_user
          session[:variation_key] = @variation_key
          redirect_to shop_path(user_id: @current_user[:user_id])
        else
          flash.now[:error] = "Failed to create variation using Experiment key: #{OPTIMIZELY_CONFIG['experiment_key']}!"
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
    
    if session[:variation_key] == 'sort_by_price'
      @products = Product::PRODUCTS.sort_by { |hsh| hsh[:price] }
    elsif session[:variation_key] == 'sort_by_name'
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
      @current_user['user_id'],
      Product::Event_Tags
    )
      Cart.create_record(@product[:id])
      flash.now[:success] = "Successfully Purchased item #{@product[:name]} for visitor #{@current_user['user_id']}!"
    else
      flash.now[:error] = @optimizely_service.errors
    end
  end

  def cart
    @enabled, succeeded = @optimizely_service.is_feature_enabled_service!(
      OPTIMIZELY_CONFIG['feature_flag_key'],
      @current_user['user_id']
    )
    if succeeded
      @cart = Cart.get_items
    else
      flash[:error] = @optimizely_service.errors
      redirect_to shop_path(user_id: @current_user['user_id'])
    end
  end

  def checkout_cart
    Cart.delete_all_items
    redirect_to shop_path(user_id: @current_user['user_id'])
  end
  
  def checkout_complete
    begin
      variation_key, succeeded = @optimizely_service.activate_service!(
       @current_user['user_id'],
       OPTIMIZELY_CONFIG['checkout_flow_experiment']
      )
      if succeeded
        if variation_key
          session[:checkout_variation_key] = variation_key
          redirect_to payment_path(user_id: @current_user['user_id'])
        else
          flash[:error] = "Failed to create variation using Experiment key: #{OPTIMIZELY_CONFIG['checkout_flow_experiment']}!"
          redirect_to cart_path(user_id: @current_user['user_id'])
        end
      else
        flash[:error] = @optimizely_service.errors
        redirect_to cart_path(user_id: @current_user['user_id'])
      end
    rescue StandardError => error
      flash[:error] = "Failed to load datafile using Project ID: #{OPTIMIZELY_CONFIG['project_id']} (#{error})!"
      redirect_to cart_path(user_id: @current_user['user_id'])
    end
  end
  
  def payment
    unless session[:checkout_variation_key]
      redirect_to cart_path(user_id: @current_user['user_id'])
    end
  end
  
  def checkout_payment
    if @optimizely_service.track_service!(
     OPTIMIZELY_CONFIG['checkout_event_key'],
     @current_user['user_id'],
     Product::Event_Tags
    )
      Cart.delete_all_items
      session.delete(:checkout_variation_key)
      flash[:success] = "Order successfully placed!"
      redirect_to shop_path(user_id: @current_user['user_id'])
    else
      flash[:error] = @optimizely_service.errors
      redirect_to payment_path(user_id: @current_user['user_id'])
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
  
  def delete_cart
    Cart.delete_all_items
    redirect_to cart_path
    flash[:success] = 'Cart items successfully removed.'
  end
  
  def logout
    delete_session!
    redirect_to new_demo_path
  end
  
  private
  
  def delete_session!
    session.delete(:current_user)
    session.delete(:variation_key)
    session.delete(:checkout_variation_key)
  end
  
  def validate_login!
    if params[:email].present? && params[:password].present?
      if params[:email] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        if OPTIMIZELY_CONFIG['experiment_key'].present?
          @current_user = {
            email: params[:email],
            user_id: params[:email].split("@").first,
            domain: (params[:email].split("@").last).split('.').first
          }
        else
          flash[:error] = "Experiment key can't be blank! add in optimizely_config.yml!"
          redirect_to new_demo_path
        end
      else
        flash[:error] = "Invalid email given!"
        redirect_to new_demo_path
      end
    else
      flash[:error] = "Email or Password can't be blank!"
      redirect_to new_demo_path
    end
    
  end

  def authenticate_user!
    if session[:current_user]
      if session[:current_user]['user_id'] == params[:user_id]
        @current_user = session[:current_user]
      else
        delete_session!
        flash[:error] = "Unauthorized user! #{params[:user_id]}"
        redirect_to new_demo_path
      end
    else
      flash[:error] = "Unauthorized user! #{params[:user_id]}"
      redirect_to new_demo_path
    end
  end
  
  def session_exists?
    if session[:current_user]
      if session[:current_user]['user_id']
        redirect_to shop_path(user_id: session[:current_user]['user_id'])
      else
        delete_session!
        redirect_to new_demo_path
      end
    else
      response = RestClient.get "#{OPTIMIZELY_CONFIG['url']}/" + "#{OPTIMIZELY_CONFIG['project_id']}.json"
      datafile = response.body
      optimizely_service = OptimizelyService.new(datafile)
      optimizely_service.instantiate! unless OptimizelyService.optimizely_client_present?
    end
  end
  
  def get_product
    @product = Product.find(params[:product_id].to_i)
  end
  
end
