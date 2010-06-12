Sham.define do
  category_name  					{ |i| "Category #{i}" }
  product_name 						{ |i| "Widget #{i}" }
  price(:unique => false)	{ ['5.00', '10.00', '20.00', '15.00' , '25.00', '7.50'].rand }
end

Product.blueprint do
	Name					{ Sham.product_name }
	Description		"Test Widget"
	Price					{ Sham.price }
	Category			{ Category.make }
end

Category.blueprint do
	Name					{ Sham.category_name }
end