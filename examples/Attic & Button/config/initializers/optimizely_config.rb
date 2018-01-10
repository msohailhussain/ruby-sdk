CONFIG_PATH="#{Rails.root}/config/optimizely_config.yml"
OPTIMIZELY_CONFIG = YAML.load_file(CONFIG_PATH)

URL = 'https://cdn.optimizely.com/json'.freeze
response = RestClient.get "#{URL}/" + "#{OPTIMIZELY_CONFIG['project_id']}.json"
DATAFILE = response.body