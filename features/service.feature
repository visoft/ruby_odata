Feature: Service Should Generate a Proxy
  In order to consume the OData
  As a user
  I want to be able to access data

Background:
  Given an ODataService exists with uri: "http://localhost:8888/SampleService/Entities.svc"
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
  Then the result should be of type "Category"

Scenario: Entity should have the correct accessors
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
	And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the result should have a method: "Id"
  And the result should have a method: "Name"
  
Scenario: Entity should fill values
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
	And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the method "Id" on the result should equal: "1"
  And the method "Name" on the result should equal: "Test Category"

Scenario: Navigation Properties should be included in results	
  Given I call "AddToProducts" on the service with a new "Product" object
	And I save changes		
  And I call "Products" on the service with args: "1"
  When I run the query
  Then the result should have a method: "Category"
  And the method "Category" on the result should be nil

Scenario: Navigation Properties should be able to be eager loaded
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
	And I save changes
	And I call "AddToProducts" on the service with a new "Product" object with Category: "@@LastSave"
	And I save changes	
  And I call "Products" on the service with args: "1"
  And I expand the query to include "Category"
  When I run the query
  Then the method "Category" on the result should be of type "Category"
  And the method "Name" on the result's method "Category" should equal: "Test Category"
	And the method "Id" on the result's method "Category" should equal: "1"

Scenario: Filters should be allowed on the root level entity
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Test Product"
  When I save changes
  When I call "Products" on the service
  And I filter the query with: "Name eq 'Test Product'"
  And I run the query
  Then the method "Name" on the result should equal: "Test Product"
  













