Feature: Type conversion
  In order to accurately perform operations
  As a user of the API 
  I want types returned to be accurately represented

Background:
  Given an ODataService exists with uri: "http://localhost:8888/SampleService/Entities.svc"
  And blueprints exist for the service

Scenario: Integers should be Fixnums
  Given I call "AddToProducts" on the service with a new "Product" object
	And I save changes
  When I call "Products" on the service
  And I run the query
  Then the "Id" method should return a Fixnum 
  
Scenario: Decimals should be BigDecimals
	Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
	When I call "Products" on the service
  And I run the query
  Then the "Price" method should return a BigDecimal

Scenario: DateTimes should be Times
	Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
	When I call "Products" on the service
  And I run the query
	Then the "AuditFields.CreateDate" method should return a Time
 
Scenario: Verify that DateTimes don't change if not modified on an update
	Given I call "AddToProducts" on the service with a new "Product" object with Name: "Test Product"
	When I save changes
	And I call "Products" on the service with args: "1"
  And I run the query
  Then I store the last query result for comparison
  When I set "Name" on the result to "Changed Test Product"
  Then the method "Name" on the result should equal: "Changed Test Product"
  And I call "update_object" on the service with the last query result
  And I save changes
  Then the save result should equal: "true"
  When I call "Products" on the service with args: "1"
  And I run the query
  Then the new query result's time "AuditFields.CreateDate" should equal the saved query result

