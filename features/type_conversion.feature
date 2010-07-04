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

