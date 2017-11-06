class Config
  include Mongoid::Document
  field :project_id, type: String
  field :experiment_key, type: String
  field :event_key, type: String
  field :project_configuration_json, type: String

  validates :project_id, presence: true

  URL="https://cdn.optimizely.com/json"
end
