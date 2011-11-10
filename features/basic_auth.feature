Feature: Service Should Access Basic Auth Protected Resources
  
Background:
  Given a HTTP BasicAuth ODataService exists using username "admin" and password "passwd"
  And blueprints exist for the service

Scenario: Service should respond to valid collections
  Then I should be able to call "Products" on the service

Scenario: Entity should fill values on protected resource
  Given I call "AddToCategories" on the service with a new "Category" object with Name: "Auth Test Category"
  And I save changes
  And I call "Categories" on the service with args: "1"
  When I run the query
  Then the method "Id" on the first result should equal: "1"
  And the method "Name" on the first result should equal: "Auth Test Category"

Scenario: Should get 401 if invalid credentials provided to protected URL
  Given a HTTP BasicAuth ODataService exists using username "admin" and password "bad_pwd" it should throw an exception with message "401 Unauthorized"

Scenario: Should get 401 if no credentials provided to protected URL
  Given a HTTP BasicAuth ODataService exists it should throw an exception with message "401 Unauthorized"
