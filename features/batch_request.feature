Feature: Batch request
  In order to minimize network traffic
  As a user of the library
  I want to be able to batch changes (Add/Update/Delete) and persist the batch instead of one at a time
  
Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

Scenario: Save Changes should allow for batch additions
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Product 1"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 2"
  When I save changes
  Then the save result should equal: "true"
  When I call "Products" on the service
  And I order by: "Name"
  And I run the query
  Then the result should be:
  | Name      |
  | Product 1 |
  | Product 2 |

Scenario: Save Changes should allow for batch updates
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Product 1"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 2"
  When I save changes
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 1'"
  And I run the query
  And I set "Name" on the result object to "Product 1 - Updated"
  And I call "update_object" on the service with the last query result object
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 2'"
  And I run the query 
  And I set "Name" on the result object to "Product 2 - Updated"
  And I call "update_object" on the service with the last query result object
  When I save changes
  When I call "Products" on the service
  And I order by: "Name"
  And I run the query
  Then the result should be:
  | Name                |
  | Product 1 - Updated |
  | Product 2 - Updated |

Scenario: Save Changes should allow for batch deletes
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Product 1"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 2"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 3"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 4"
  When I save changes
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 2'"
  And I run the query
  And I call "delete_object" on the service with the last query result object
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 3'"
  And I run the query 
  And I call "delete_object" on the service with the last query result object
  When I save changes
  When I call "Products" on the service
  And I order by: "Name"
  And I run the query
  Then the result should be:
  | Name      |
  | Product 1 |
  | Product 4 |

Scenario: Save Changes should allow for a mix of adds, updates, and deletes to be batched
  Given the following Products exist:
  | Name      |
  | Product 1 |
  | Product 2 |
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 3"
  And I call "AddToProducts" on the service with a new "Product" object with Name: "Product 4"
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 1'"
  And I run the query
  And I set "Name" on the result object to "Product 1 - Updated"
  And I call "update_object" on the service with the last query result object
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Product 2'"
  And I run the query
  And I call "delete_object" on the service with the last query result object
  When I save changes
  When I call "Products" on the service
  And I order by: "Name"
  And I run the query
  Then the result should be:
  | Name                |
  | Product 1 - Updated |
  | Product 3           |
  | Product 4           |

