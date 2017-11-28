class Product
  PRODUCTS = [
     { id: 1, name: "Long Sleeve Swing Shirt", color: "Baby Blue", category: "Shirts", price: 54, image_url: "item_1.png" },
     { id: 2, name: "Bo Henry", color: "Khaki", category: "Shorts", price: 37, image_url: "item_2.png" },
     { id: 3, name: "The \"Go\" Bag", color: "Forest Green", category: "Bags", price:118, image_url: "item_3.png" },
     { id: 4, name: "Springtime", color: "Rose", category: "Dresses", price: 84, image_url: "item_4.png" },
     { id: 5, name: "The Night Out", color: "Olive Green", category: "Dresses", price: 153, image_url: "item_5.png" },
     { id: 6, name: "Dawson Trolley", color: "Pine Green", category: "Shirts", price: 107, image_url: "item_6.png" }
  ]

  def self.find id
    PRODUCTS.find {|product| product[:id] == id}
  end

end
