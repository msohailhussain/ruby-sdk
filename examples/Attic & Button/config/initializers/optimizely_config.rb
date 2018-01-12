CONFIG_PATH="#{Rails.root}/config/optimizely_config.yml"
OPTIMIZELY_CONFIG = YAML.load_file(CONFIG_PATH)

response = RestClient.get "#{OPTIMIZELY_CONFIG['url']}/" + "#{OPTIMIZELY_CONFIG['project_id']}.json"
DATAFILE = response.body
