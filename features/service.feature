Feature: Service Should Generate a Proxy
  In order to consume the OData
  As a user
  I want to be able to access data
  
Background:
	Given an ODataService exists with uri: "http://localhost:2301/Services/Entities.svc"

Scenario: Service should respond to valid collections
  Then I should be able to call "plans" on the service

Scenario: Service should not respond to an invalid collection
  Then I should not be able to call "X" on the service

Scenario: Service should respond to accessing a single entity by ID
  Then I should be able to call "plans" on the service with args: "1"

Scenario: Access an entity by ID should return the entity type
  Given I call "plans" on the service with args: "1"
  When I run the query
  Then the result should be of type "Plan"

Scenario: Entity should have the correct accessors
  Given I call "plans" on the service with args: "1"
  When I run the query
  Then the result should have a method: "id"
  And the result should have a method: "code"
  And the result should have a method: "name"
  And the result should have a method: "description"
  And the result should have a method: "price"
  And the result should have a method: "promo_days"
  And the result should have a method: "expiration_date"
  And the result should have a method: "is_trial"
  And the result should have a method: "frequency_days"
  And the result should have a method: "pay_pal_button_id"
  And the result should have a method: "plan_type"
  
Scenario: Entity should an id
  Given I call "plans" on the service with args: "1"
  When I run the query
  Then the method "id" on the result should equal: "1"
  And the method "code" on the result should equal: "TRL7DAY"
  And the method "name" on the result should equal: "7 Day Free Trial"







