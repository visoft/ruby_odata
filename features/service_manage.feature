Feature: Service management
  In order to manage entities
  As a admin
  I want to be able to add, edit, and delete entities

Background:
  Given an ODataService exists with uri: "http://localhost:2301/Services/Entities.svc"
	And blueprints exist for the service

Scenario: Service should respond to AddToEntityName for adding objects
  Given I call "AddToTempAccounts" on the service with a new "TempAccount" object with FirstName: "John", LastName: "Doe"
  When I save changes
  Then the save result should be of type "TempAccount"
	And the method "FirstName" on the save result should equal: "John"
	And the method "LastName" on the save result should equal: "Doe"






