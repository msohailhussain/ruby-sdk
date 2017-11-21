class Visitor
  VISITORS = [
     { id: 10001, name: "Mike", age: 23 },
     { id: 10002, name: "Ali", age: 29 },
     { id: 10003, name: "Sally", age: 18 },
     { id: 10004, name: "Jennifer", age: 44 },
     { id: 10005, name: "Randall", age: 29 }
  ]
  
  def self.find id
    VISITORS.find {|visitor| visitor[:id] == id}
  end
end
