class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def optimizely_client_present?
    unless OptimizelyService.optimizely_client_present?
      redirect_to demo_config_path
    end
  end

  def get_visitor
    visitor = Visitor.find(params[:id].to_i)
    @visitor = visitor.present? ? visitor : Visitor::VISITORS.first
  end

end
