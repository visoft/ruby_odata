Feature: Service management
  In order to manage entities
  As a admin
  I want to be able to add, edit, and delete entities

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

Scenario: Service should respond to AddToEntityName for adding objects
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Sample Product"
  When I save changes
  Then the first save result should be of type "Product"
  And the method "Name" on the first save result should equal: "Sample Product"

Scenario: Service should allow for deletes
  Given I call "AddToProducts" on the service with a new "Product" object
  When I save changes
  Then the first save result should be of type "Product"
  When I call "delete_object" on the service with the last save result object
  And I save changes
  Then the save result should equal: "true" 
  And no "Products" should exist

Scenario: Untracked entities shouldn't be able to be deleted
  Given I call "delete_object" on the service with a new "Product" object it should throw an exception with message "You cannot delete a non-tracked entity"

Scenario: Entities should be able to be updated
  Given I call "AddToProducts" on the service with a new "Product" object with Name: "Test Product"
  When I save changes
  And I call "Products" on the service with args: "1"
  And I run the query
  Then the method "Name" on the first result should equal: "Test Product"
  When I set "Name" on the result object to "Changed Test Product"
  Then the method "Name" on the first result should equal: "Changed Test Product"
  And I call "update_object" on the service with the last query result object
  And I save changes
  Then the save result should equal: "true"
  When I call "Products" on the service with args: "1"
  And I run the query
  Then the method "Name" on the first result should equal: "Changed Test Product"

Scenario: Untracked entities shouldn't be able to be updated
  Given I call "update_object" on the service with a new "Product" object it should throw an exception with message "You cannot update a non-tracked entity"

Scenario: Related entities shouldn't be recreated on a child add
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Test Category"
  And I save changes
  And I call "AddToProducts" on the service with a new "Product" object with Category: "@@LastSave.first"
  And I save changes	
  And I call "Products" on the service with args: "1"
  And I expand the query to include "Category"
  When I run the query
  Then the method "Id" on the result object's method "Category" should equal: "1"
