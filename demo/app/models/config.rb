class Config < ActiveHash::Base
  @@data = []
  
  fields :project_id, :experiment_key, :event_key, :project_configuration_json
  
  URL="https://cdn.optimizely.com/json"
  
  def self.find_by_project_id project_id
    @@data.find { |config| config.project_id == project_id }
  end
  
  def self.find_or_create_by_project_id project_id
    @@data.find { |config| config.project_id == project_id } || (@@data << self.create(project_id: project_id)).last
  end
  
  def update params
    self.experiment_key = params[:experiment_key]
    self.event_key = params[:event_key]
    self.project_configuration_json = params[:project_configuration_json]
    self.save
  end
  
end