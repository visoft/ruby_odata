@error_handling
Feature: Error handling
  In order to assist debugging
  As a user
  I want more debug information when an error occurs communicating with the server

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service

Scenario: Violate a data type conversion (empty string to decimal)
  Given I call "AddToProducts" on the service with a new "Product" object with Price: ""
  When I save changes it should throw an exception with message containing "Error encountered in converting the value"
