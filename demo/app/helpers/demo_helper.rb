module DemoHelper
  def generate_json_view json
    JSON.pretty_generate JSON.parse(json)
  end
end
