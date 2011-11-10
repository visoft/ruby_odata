Feature: Service Should Generate a Proxy
  In order to consume the OData
  As a user
  I want to be able to access data

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

Scenario: Service should respond to valid collections
  Then I should be able to call "Categories" on the service

Scenario: Service should not respond to an invalid collection
  Then I should not be able to call "X" on the service

Scenario: Service should respond to accessing a single entity by ID
  Then I should be able to call "Categories" on the service with args: "1"

Scenario: Access an entity by ID should return the entity type
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the first result should be of type "Category"

Scenario: Entity should have the correct accessors
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the first result should have a method: "Id"
  And the first result should have a method: "Name"
  
Scenario: Entity should fill values
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the method "Id" on the first result should equal: "1"
  And the method "Name" on the first result should equal: "Test Category"

Scenario: Navigation Properties should be included in results	
  Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes		
  And I call "Products" on the service with args: "1"
  When I run the query
  Then the first result should have a method: "Category"
  And the method "Category" on the first result should be nil

