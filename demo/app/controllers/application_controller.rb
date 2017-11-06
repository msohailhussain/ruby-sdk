class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def check_optimizely_client
    unless OptimizelyService.optimizely_client_present?
      flash[:alert] = "Optimizely client does not exists!"
      redirect_to demo_config_path
    end
  end

  def get_visitor
    visitor = Visitor.where(id: params[:id].to_i).first
    @visitor = visitor.present? ? visitor : Visitor.first
  end

end
