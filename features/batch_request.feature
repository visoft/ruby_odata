Feature: Batch request
  In order to minimize network traffic
  As a user of the library
  I want to be able to batch changes (Add/Update/Delete) and persist the batch instead of one at a time
  
Background:
  Given an ODataService exists with uri: "http://localhost:8888/SampleService/Entities.svc"
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

  

  


