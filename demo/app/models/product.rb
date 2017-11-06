class Product
  include Mongoid::Document
  field :id, type: String
  field :name, type: String
  field :color, type: String
  field :category, type: String
  field :price, type: BigDecimal

end
