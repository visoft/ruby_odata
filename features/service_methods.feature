@service_methods
Feature: Service methods
  In order to use a WCF Data Service more efficiently
  As a consumer
  I want to be able to utilize custom WCF DS methods

Background:
  Given a HTTP ODataService exists
  And blueprints exist for the service


Scenario: A custom web get (no parameters) that returns an entity
  Given a category exists
  And I call the service method "EntityCategoryWebGet"
  Then the first result should be of type "Category"

Scenario: A custom web get (with parameters) that returns a single entity
  Given a category: "cat1" exists with Id: 1
  When I call the service method "EntitySingleCategoryWebGet" with 1
  Then the result should be of type "Category"
  And the method "Id" on the result should equal: "1"

Scenario: A custom web get that returns a collection of primitive types
  Given the following categories exist:
  | Name |
  | Cat1 |
  | Cat2 |
  | Cat3 |
  When I call the service method "CategoryNames"
  Then the primitive results should be:
  | Cat1  |
  | Cat2  |
  | Cat3  |

Scenario: A custom web get that returns a single primitive type
  Given a category exists
  When I call the service method "FirstCategoryId"
  Then the integer result should be 1
