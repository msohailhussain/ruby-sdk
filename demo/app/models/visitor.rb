class Visitor
  VISITORS = [
    {id: 10_001, name: 'Mike', age: 23},
    {id: 10_002, name: 'Ali', age: 29},
    {id: 10_003, name: 'Sally', age: 18},
    {id: 10_004, name: 'Jennifer', age: 44},
    {id: 10_005, name: 'Randall', age: 29}
  ].freeze

  def self.find(id)
    VISITORS.find { |visitor| visitor[:id] == id }
  end
end
