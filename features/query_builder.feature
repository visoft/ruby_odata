Feature: Query Builder
  In order to query OData services
  As a user
  I want to be able to perform valid OData protocol operations 

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

# Expand
Scenario: Navigation Properties should be able to be eager loaded
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And I call "AddToProducts" on the service with a new "Product" object with Category: "@@LastSave.first"
  And I save changes	
  And I call "Products" on the service with args: "1"
  And I expand the query to include "Category"
  When I run the query
  Then the method "Category" on the first result should be of type "Category"
  And the method "Name" on the first result's method "Category" should equal: "Test Category"
  And the method "Id" on the first result's method "Category" should equal: "1"


# Filters
Scenario: Filters should be allowed on the root level entity
# Filter
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Test Product"
  When I save changes
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Test Product'"
  And I run the query
  Then the method "Name" on the first result should equal: "Test Product"


# Order By
Scenario: Order by should be allowed on the root level entity
  Given the following Products exist:
  | Name      |
  | Product 2 |
  | Product 4 |
  | Product 5 |
  | Product 1 |
  | Product 3 |
  When I call "Products" on the service
  And I order by: "Name"
  And I run the query
  Then the result should be:
  | Name      |
  | Product 1 |
  | Product 2 |
  | Product 3 |
  | Product 4 |
  | Product 5 |

Scenario: Order by should accept sorting descending
  Given the following Products exist:
  | Name      |
  | Product 2 |
  | Product 4 |
  | Product 5 |
  | Product 1 |
  | Product 3 |
  When I call "Products" on the service
  And I order by: "Name desc"
  And I run the query
  Then the result should be:
  | Name      |
  | Product 5 |
  | Product 4 |
  | Product 3 |
  | Product 2 |
  | Product 1 |

Scenario: Order by should access sorting acsending
  Given the following Products exist:
  | Name      |
  | Product 2 |
  | Product 4 |
  | Product 5 |
  | Product 1 |
  | Product 3 |
  When I call "Products" on the service
  And I order by: "Name asc"
  And I run the query
  Then the result should be:
  | Name      |
  | Product 1 |
  | Product 2 |
  | Product 3 |
  | Product 4 |
  | Product 5 |


# Skip
Scenario: Skip should be allowed on the root level entity
  Given the following Products exist:
  | Name      |
  | Product 1 |
  | Product 2 |
  | Product 3 |
  | Product 4 |
  | Product 5 | 
  When I call "Products" on the service
  And I skip 3
  And I run the query
  Then the result should be:
  | Name      |
  | Product 4 |
  | Product 5 |  


# Top
Scenario: Top should be allowed on the root level entity
  Given the following Products exist:
  | Name      |
  | Product 1 |
  | Product 2 |
  | Product 3 |
  | Product 4 |
  | Product 5 | 
  When I call "Products" on the service
  And I ask for the top 3
  And I run the query
  Then the result should be:
  | Name      |
  | Product 1 |
  | Product 2 | 
  | Product 3 |

Scenario: Top should be able to be used along with skip for paging
  Given the following Products exist:
  | Name      |
  | Product 1 |
  | Product 2 |
  | Product 3 |
  | Product 4 |
  | Product 5 | 
  | Product 6 |  
  When I call "Products" on the service
  And I skip 2
  And I ask for the top 2
  And I run the query
  Then the result should be:
  | Name      |
  | Product 3 |
  | Product 4 |  


# Links
@current
Scenario: Navigation Properties should be able to represented as links
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And the following Products exist:
  | Name      | Category         |
  | Product 1 | @@LastSave.first |
  | Product 2 | @@LastSave.first |
  | Product 3 | @@LastSave.first |
  When I call "Categories" on the service with args: "1"
  And I ask for the links for "Products"
  And I run the query
  Then the result count should be 3
  Then the method "path" on the result object should equal: "/SampleService/Entities.svc/Products(1)"
