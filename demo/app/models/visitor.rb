class Visitor
  include Mongoid::Document
  field :id, type: String
  field :name, type: String
  field :age, type: Integer

  def user_attributes
    attributes = {'name' => name.to_s, 'age'=> age.to_s}
  end
end
