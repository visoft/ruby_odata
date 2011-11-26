Feature: Service methods
  In order to use a WCF Data Service more efficiently
  As a consumer
  I want to be able to utilize custom WCF DS methods

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service  

@wip  
Scenario: A custom web get (no parameters) that returns an entity
  Given a category exists
  And I call "EntityCategoryWebGet" on the service
  When I run the query
  Then the first result should be of type "Category"



  
