class Product
  PRODUCTS = [
     { id: 1, name: "Long Sleeve Swing Shirt", color: "Baby Blue", category: "Shirts", price: 54 },
     { id: 2, name: "Bo Henry", color: "Khaki", category: "Shorts", price: 37 },
     { id: 3, name: "The \"Go\" Bag", color: "Forest Green", category: "Bags", price:118 },
     { id: 4, name: "Springtime", color: "Rose", category: "Dresses", price: 84 },
     { id: 5, name: "The Night Out", color: "Olive Green", category: "Dresses", price: 153 },
     { id: 6, name: "Dawson Trolley", color: "Pine Green", category: "Shirts", price: 107 }
  ]

  def self.find id
    PRODUCTS.find {|product| product[:id] == id}
  end

end
