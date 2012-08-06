class AuditFields
  extend Machinist::Machinable
end

class Product
  extend Machinist::Machinable
end

class Category
  extend Machinist::Machinable
end

AuditFields.blueprint do
  CreatedBy     { "Machinist" }
end

Product.blueprint do
  Name          { "Widget #{sn}" }
  Description   { "Test Widget" }
  Price         { ["10.25", "25.00", "50.00", "75.50", "100.00"].sample }
  Category      { Category.make }
  AuditFields   { AuditFields.make }
end

Category.blueprint do
  Name          { "Category #{sn}" }
  AuditFields   { AuditFields.make }
end