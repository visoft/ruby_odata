Feature: Complex types
  In order to fully support OData services
  As a user of ruby_odata
  I want to be able to manage objects with complex types

Background:
  Given an ODataService exists with uri: "http://localhost:8888/SampleService/Entities.svc"
  And blueprints exist for the service

Scenario: The proxy must generate classes for complex types if they exist
  Then a class named "AuditFields" should exist

Scenario: Complex properties on an entity must be the correct type
  Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes		
  And I call "Products" on the service with args: "1"
  When I run the query
  Then the result should have a method: "AuditFields"
  And the method "AuditFields" on the result should be of type "AuditFields"

Scenario: Complex properties on an entity must be filled
  Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
  And I call "Products" on the service with args: "1"
  When I run the query
  Then the result should have a method: "AuditFields"
  When I call "CreateDate" for "AuditFields" on the result 
  Then the operation should not be null 

# TODO: This scenario should have the AuditFields.CreatedBy field set in the Given
# instead it is set by the blueprint  
Scenario: Complex properties should be able to be added
  Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
  And I call "Products" on the service with args: "1"
  When I run the query
  Then the method "CreatedBy" on the result's method "AuditFields" should equal: "Cucumber"
  
Scenario: Complex propertis should be able to be updated
  Given I call "AddToProducts" on the service with a new "Product" object
  And I save changes
  And I call "Products" on the service with args: "1"
  When I run the query
  When I set "CreatedBy" on the result's method "AuditFields" to "This Test"
  And I call "update_object" on the service with the last query result
  And I save changes
  Then the save result should equal: "true"
  When I call "Products" on the service with args: "1"
  And I run the query
  Then the method "CreatedBy" on the result's method "AuditFields" should equal: "This Test"


