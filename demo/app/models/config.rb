class Config
  attr_accessor :project_id
  attr_accessor :experiment_key
  attr_accessor :event_key
  attr_accessor :project_configuration_json
  
  # validates :project_id, presence: true

  URL="https://cdn.optimizely.com/json"
  
  def initialize(project_id = nil, experiment_key = nil, event_key = nil, project_configuration_json = nil)
    @project_id = project_id
    @experiment_key = experiment_key
    @event_key = event_key
    @project_configuration_json = project_configuration_json
  end
  
end
