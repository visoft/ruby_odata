Feature: Service management
  In order to manage entities
  As a admin
  I want to be able to add, edit, and delete entities

Background:
  Given an ODataService exists with uri: "http://localhost:8888/SampleService/Entities.svc"
	And blueprints exist for the service

Scenario: Service should respond to AddToEntityName for adding objects
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Sample Product"
  When I save changes
  Then the save result should be of type "Product"
	And the method "Name" on the save result should equal: "Sample Product"

Scenario: Service should allow for deletes
  Given I call "AddToProducts" on the service with a new "Product" object
  When I save changes
  Then the save result should be of type "Product"
  When I call "delete_object" on the service with the last save result
  And I save changes
  Then the save result should equal: "true"

Scenario: Untracked entities shouldn't be able to be deleted
	Given I call "delete_object" on the service with a new "Product" object it should throw an exception

