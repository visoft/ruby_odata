Feature: Type conversion
  In order to accurately perform operations
  As a user of the API 
  I want types returned to be accurately represented

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

Scenario: Integers should be Fixnums
  Given I call "AddToProducts" on the service with a new "Product" object
	And I save changes
  When I call "Products" on the service
  And I run the query
  Then the "Id" method on the object should return a Fixnum 
  
Scenario: Decimals should be BigDecimals
	Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
	When I call "Products" on the service
  And I run the query
  Then the "Price" method on the object should return a BigDecimal

Scenario: DateTimes should be Times
	Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
	When I call "Products" on the service
  And I run the query
	Then the "AuditFields.CreateDate" method on the object should return a Time
 
Scenario: Verify that DateTimes don't change if not modified on an update
	Given I call "AddToProducts" on the service with a new "Product" object with Name: "Test Product"
	When I save changes
	And I call "Products" on the service with args: "1"
  And I run the query
  Then I store the last query result object for comparison
  When I set "Name" on the result object to "Changed Test Product"
  Then the method "Name" on the first result should equal: "Changed Test Product"
  And I call "update_object" on the service with the last query result object
  And I save changes
  Then the save result should equal: "true"
  When I call "Products" on the service with args: "1"
  And I run the query
  Then the new query first result's time "AuditFields.CreateDate" should equal the saved query result

Scenario: DateTimes should be able to be null
	Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
	When I call "Products" on the service
  And I run the query
  Then the "DiscontinuedDate" method on the object should return a NilClass


