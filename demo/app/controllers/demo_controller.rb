class DemoController < ApplicationController

  before_action :validate_config!, only: :create
  before_action :get_visitor, only: [:shop,:buy]
  before_action :get_project_configuration, only: [:shop,:buy]
  before_action :check_optimizely_client, only: [:shop,:buy]
  before_action :get_product, only: [:buy]

  def new
    if session[:config_project_id].present?
      @config = Config.where(project_id: session[:config_project_id]).first
      get_or_generate_optimizely_client
    else
      @config = Config.new
    end
  end

  def create
    begin
      response = RestClient.get "#{Config::URL}/"+"#{@config.project_id}.json"
      @optimizely_service = OptimizelyService.new(response.body)
      if @optimizely_service.instantiate!
        if @config.update(
            demo_params.merge(
                project_configuration_json: response.body
            )
        )
          session[:config_project_id] = @config.project_id
        else
          flash[:error] = @config.errors.full_messages.first
        end
      else
        flash[:error] = @optimizely_service.errors
      end
    rescue StandardError => error
      flash[:error] = error
    end
    render "new"
  end

  def visitors
    @visitors = Visitor.all
  end

  def shop
    @products = Product.all
    @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
    if @optimizely_service.activate_service!(@visitor,@config.experiment_key )
      @optimizely_service
    else
      flash[:error] = @optimizely_service.errors
      redirect_to demo_config_path
    end
  end

  def buy
    @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
    if @optimizely_service.track_service!(
        @config.event_key,
        @visitor,
        @product.present? ? @product.as_json.except("_id") : {}
    )
      flash[:success] = "Successfully Purchased item #{@product.try(:name)} for visitor #{@visitor.name}!"
    else
      flash[:error] = @optimizely_service.errors
    end
    redirect_to shop_path
  end

  private

  def demo_params
    params[:config].permit(:project_id, :experiment_key, :event_key,:project_configuration_json)
  end

  def validate_config!
    @config = Config.where(project_id: demo_params[:project_id]).first_or_create
    if @config.valid?
      @config
    else
      flash[:error] = @config.errors.full_messages.first
      render "new"
    end
  end

  def get_project_configuration
    @config = Config.where(project_id: session[:config_project_id]).first
    unless @config.present? && @config.try(:experiment_key).present?
      flash[:alert] = "Project id and Experiment key can't be blank!"
      redirect_to demo_config_path
    end
  end

  def get_or_generate_optimizely_client
    if @config.present?
      if OptimizelyService.optimizely_client_present?
        @config
      else
        @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
        if @optimizely_service.instantiate!
          @config
        else
          @config = Config.new
        end
      end
    else
      @config = Config.new
    end
  end

  def get_product
    @product = Product.find(params[:product_id].to_i)
  end

end
