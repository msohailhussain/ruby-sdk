# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

unless Visitor.count > 0
    Visitor.create(
        [
            { id: 10001, name: "Mike", age: 23 },
            { id: 10002, name: "Ali", age: 29 },
            { id: 10003, name: "Sally", age: 18 },
            { id: 10004, name: "Jennifer", age: 44 },
            { id: 10005, name: "Randall", age: 29 }
        ]
    )
end

unless Product.count > 0
    Product.create(
        [
            { id: 1, name: "Long Sleeve Swing Shirt", color: "Baby Blue", category: "Shirts", price: 54 },
            { id: 2, name: "Bo Henry", color: "Khaki", category: "Shorts", price: 37 },
            { id: 3, name: "The \"Go\" Bag", color: "Forest Green", category: "Bags", price:118 },
            { id: 4, name: "Springtime", color: "Rose", category: "Dresses", price: 84 },
            { id: 5, name: "The Night Out", color: "Olive Green", category: "Dresses", price: 153 },
            { id: 6, name: "Dawson Trolley", color: "Pine Green", category: "Shirts", price: 107 }
        ])
end

