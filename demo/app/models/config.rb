class Config < RedisOrm::Base
  property :project_id, String
  property :experiment_key, String
  property :event_key, String
  property :project_configuration_json, String

  validates_presence_of :project_id
  
  index :project_id
  index [:project_id, :event_key, :experiment_key]
  
  URL="https://cdn.optimizely.com/json"
  
  def self.find_or_create_by_project_id project_id
    self.find(:first, conditions: {project_id: project_id}) || self.create(project_id: project_id)
  end
  
end
