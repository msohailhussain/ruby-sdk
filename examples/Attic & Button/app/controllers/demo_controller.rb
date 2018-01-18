# frozen_string_literal: true

#
#    Copyright 2018, Optimizely and contributors
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
  before_action :authenticate_user!, except: %i[new create logout guest_shop]
  before_action :initialize_optimizely_client!, only: %i[shop buy cart payment checkout_payment]
  before_action :session_exists?, only: [:guest_shop]
  before_action :product_exists!, only: %i[buy update_cart]
  before_action :discount_feature_enabled?, only: :cart

  def create
    error_response("Email or Password can't be blank!") unless params[:email].present? && params[:password].present?
    error_response('Invalid Email!') unless params[:email] =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    error_response("Experiment key can't be blank! add in optimizely_config.yml!") unless OPTIMIZELY_CONFIG['experiment_key'].present?
    session[:current_user] = {
      email: params[:email],
      user_id: SecureRandom.hex(10),
      name: params[:email].split('@').first,
      domain: params[:email].split('@').last,
      cart: []
    }
  end

  def guest_shop
    unless session[:current_user] && session[:current_user]['user_id']
      delete_session!
      session[:current_user] = {
        user_id: SecureRandom.hex(10),
        cart: []
      }.as_json
    end
    redirect_to shop_path(user_id: session[:current_user]['user_id'])
  end

  def shop
    @variation_key = session[:variation_key]
    unless @variation_key
      begin
        @variation_key, succeeded = @optimizely_service.activate_service!(
          @current_user,
          OPTIMIZELY_CONFIG['experiment_key']
        )
        if succeeded
          if @variation_key
            session[:variation_key] = @variation_key
          else
            flash.now[:error] = "Failed to create variation using Experiment key: #{OPTIMIZELY_CONFIG['experiment_key']}!"
          end
        else
          flash[:error] = @optimizely_service.errors
        end
      rescue StandardError => error
        flash.now[:error] = "Failed to load datafile using Project ID: #{OPTIMIZELY_CONFIG['project_id']} (#{error})!"
      end
    end
    @products = if @variation_key == 'sort_by_price'
                  Product::PRODUCTS.sort_by { |hsh| hsh[:price] }
                elsif @variation_key == 'sort_by_name'
                  Product::PRODUCTS.sort_by { |hsh| hsh[:name] }
                else
                  Product::PRODUCTS
                end
  end

  def buy
    if @optimizely_service.track_service!(
      OPTIMIZELY_CONFIG['event_key'],
      @current_user,
      Product::Event_Tags
    )
      session[:current_user]['cart'] << @product[:id]
      flash.now[:success] = "Item #{@product[:name]} added to Cart!"

    else
      flash.now[:error] = @optimizely_service.errors
    end
  end

  def cart
    if @discount_feature_enabled
      @discount_percentage, succeeded = @optimizely_service.get_feature_variable_integer_service!(
        OPTIMIZELY_CONFIG['discount_feature_flag'],
        OPTIMIZELY_CONFIG['discount_feature_variable'],
        @current_user
      )
      if succeeded
        @buy_now_enabled, succeeded = @optimizely_service.feature_enabled_service?(
          OPTIMIZELY_CONFIG['buy_now_feature_flag'],
          @current_user
        )
        unless succeeded
          flash[:error] = @optimizely_service.errors
          redirect_to shop_path(user_id: @current_user['user_id'])
        end
      else
        flash[:error] = @optimizely_service.errors
        redirect_to shop_path(user_id: @current_user['user_id'])
      end
    else
      @discount_percentage = 0
    end

    @cart = if session[:current_user]['cart']
              session[:current_user]['cart'].group_by { |e| e }.map { |k, v| [k, v.length] }.to_h
            else
              []
            end
  end

  def checkout_cart
    flash[:success] = 'Thank you for shopping!'
    session[:current_user]['cart'] = []
    redirect_to shop_path(user_id: @current_user['user_id'])
  end

  def show_receipt
    @cart = if session[:current_user]['cart'].empty?
              []
            else
              session[:current_user]['cart'].group_by { |e| e }.map { |k, v| [k, v.length] }.to_h
            end
    @discount_percentage = params[:discount_percentage].to_i
  end

  def payment
    variation_key, succeeded = @optimizely_service.activate_service!(
      @current_user,
      OPTIMIZELY_CONFIG['checkout_flow_experiment']
    )
    if succeeded
      if variation_key
        @total_price = params[:total_price].to_i
        session[:checkout_variation_key] = variation_key
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

  def checkout_payment
    if @optimizely_service.track_service!(
      OPTIMIZELY_CONFIG['checkout_event_key'],
      @current_user,
      'revenue' => params[:total_price].to_i
    )
      session[:current_user]['cart'] = []
      session.delete(:checkout_variation_key)
      flash[:success] = 'Thank you for shoping'
      redirect_to shop_path(user_id: @current_user['user_id'])
    else
      flash[:error] = @optimizely_service.errors
      redirect_to payment_path(user_id: @current_user['user_id'])
    end
  end

  def log_messages
    # Returns all log messages
    @logs = LogMessage.all_logs(@current_user['user_id'])
  end

  def delete_messages
    LogMessage.delete_all_logs(@current_user['user_id'])
    redirect_to messages_path(user_id: @current_user['user_id'])
    flash[:success] = 'log messages deleted successfully.'
  end

  def delete_cart
    session[:current_user]['cart'] = []
    redirect_to cart_path
    flash[:success] = 'Cart items successfully removed.'
  end

  def logout
    delete_session!
    redirect_to guest_shop_path
  end

  def update_cart
    return render json: {success: false, message: 'Product not found!'} unless @product
    return render json: {success: false, message: 'Invalid Quantity! valid up to 100'} unless params[:quantity].to_i.between?(0, 100)
    session[:current_user]['cart'].delete(@product[:id])
    1.upto(params[:quantity].to_i) { session[:current_user]['cart'] << @product[:id] }
    render json: {success: true}
  end

  private

  def initialize_optimizely_client!
    @optimizely_service = OptimizelyService.new(DATAFILE)
    @optimizely_service.instantiate! unless OptimizelyService.optimizely_client_present?
    LogMessage.assign_user!(@current_user['user_id']) if @current_user
  end

  def delete_session!
    session.delete(:current_user)
    session.delete(:variation_key)
    session.delete(:checkout_variation_key)
  end

  def authenticate_user!
    unless session[:current_user] && (session[:current_user]['user_id'] == params[:user_id])
      delete_session!
      session[:current_user] = {
        user_id: SecureRandom.hex(10),
        cart: []
      }
    end
    @current_user = session[:current_user].as_json
  end

  def session_exists?
    return unless session[:current_user]
    response = RestClient.get "#{OPTIMIZELY_CONFIG['url']}/" + "#{OPTIMIZELY_CONFIG['project_id']}.json"
    datafile = response.body
    optimizely_service = OptimizelyService.new(datafile)
    optimizely_service.instantiate! unless OptimizelyService.optimizely_client_present?
    LogMessage.assign_user!(session[:current_user]['user_id'])
  end

  def product_exists!
    @product = Product.find(params[:product_id].to_i)
  end

  def discount_feature_enabled?
    @discount_feature_enabled, succeeded = @optimizely_service.feature_enabled_service?(
      OPTIMIZELY_CONFIG['discount_feature_flag'],
      @current_user
    )
    return if succeeded
    flash[:error] = @optimizely_service.errors
    redirect_to shop_path(user_id: @current_user['user_id'])
  end

  def error_response(error)
    @error = error
    respond_to do |format|
      format.html do
        flash[:error] = @error
        redirect_to new_demo_path
      end
      format.js
    end
  end
end
