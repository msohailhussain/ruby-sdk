class DemoController < ApplicationController
  before_action :validate_config!, only: :create
  before_action :get_visitor, only: [:shop, :buy]
  before_action :get_project_configuration, only: [:shop, :buy]
  before_action :optimizely_client_present?, only: [:shop, :buy]
  before_action :get_product, only: [:buy]

  def new
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
      response = RestClient.get "#{Config::URL}/" + "#{@config.project_id}.json"
      @optimizely_service = OptimizelyService.new(response.body)
      if @optimizely_service.instantiate!
        if @config.update(
          demo_params.merge(project_configuration_json: response.body)
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
    render 'new'
  end

  def visitors
    # Returns list of visitors from model Visitor
    @visitors = Visitor::VISITORS
  end

  def shop
    # Calls before_action get_visitor from Application Controller to get visitor
    # Calls before_action get_project_configuration from Private methods to get config object
    # Calls before_action optimizely_client_present? to check optimizely_client object exists
    # Lists all products from Product model
    # Calls optimizely client activate method to create variation(Static object) in OptimizelyService class

    @products = Product::PRODUCTS
    @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
    if @optimizely_service.activate_service!(@visitor, @config.experiment_key)
      @optimizely_service
    else
      flash[:error] = @optimizely_service.errors
      redirect_to demo_config_path
    end
  end

  def buy
    # Calls before_action get_visitor from Application Controller to get visitor
    # Calls before_action get_project_configuration from Private methods to get config object
    # Calls before_action optimizely_client_present? to check optimizely_client object exists
    # Calls before_action get_product to get selected project
    # Calls optmizely client's track method from OptimizelyService class
    @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
    if @optimizely_service.track_service!(
      @config.event_key,
      @visitor,
      @product.present? ? @product.except(:id) : {}
    )
      flash[:success] = "Successfully Purchased item #{@product[:name]} for visitor #{@visitor[:name]}!"
    else
      flash[:error] = @optimizely_service.errors
    end
    redirect_to messages_path
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

  private

  def demo_params
    # Params passed on form submit to be permitted before save
    params[:config].permit(:project_id, :experiment_key, :event_key, :project_configuration_json)
  end

  def validate_config!
    @config = Config.find_or_create_by_project_id(demo_params[:project_id])
    if @config.valid?
      @config
    else
      flash[:error] = @config.errors.full_messages.first
      render 'new'
    end
  end

  def get_project_configuration
    @config = Config.find_by_project_id(session[:config_project_id])
    unless @config.present? && @config.try(:experiment_key).present?
      flash[:alert] = "Project id or Experiment key can't be blank!"
      redirect_to demo_config_path
    end
  end

  def get_config
    return @config if OptimizelyService.optimizely_client_present?
    @optimizely_service = OptimizelyService.new(@config.project_configuration_json)
    @config = @optimizely_service.instantiate! ? @config : Config.new
  end

  def get_product
    @product = Product.find(params[:product_id].to_i)
  end
end
