# ruby_odata

The **Open Data Protocol** (OData) is a fantastic way to query and update data over standard Web technologies.  The ruby_odata library acts as a consumer of OData services.

[![Build Status](https://secure.travis-ci.org/visoft/ruby_odata.png)](http://travis-ci.org/visoft/ruby_odata)

## Resources

* Source Code (hosted on GitHub): http://github.com/visoft/ruby_odata
* Documentation (hosted on rdoc.info): http://rdoc.info/projects/visoft/ruby_odata
* Issue tracking (hosted on GitHub): https://github.com/visoft/ruby_odata/issues
* Wiki (hosted on GitHub): http://wiki.github.com/visoft/ruby_odata/
* Gem (hosted on Gemcutter): http://gemcutter.org/gems/ruby_odata
* Blog articles:
    * [Introducing a Ruby OData Client Library](http://bit.ly/IntroRubyOData)
    * [Ruby OData Update v0.0.7](http://bit.ly/ruby_odata007)
    * [Ruby OData Update v0.0.8](http://bit.ly/ruby_odata008)
    * [Ruby OData Update v0.0.10](http://bit.ly/ruby_odata0010)
    * [Major Ruby OData Update v0.1.0](http://bit.ly/ruby_odata010)

## Installation
You can install ruby_odata as a gem using:

    gem install ruby_odata

## Usage

### Instantiating the Service
There are various options that you can pass when creating an instance of the service, these include:
* username: username for http basic auth
* password: password for http basic auth
* verify_ssl: false if no verification, otherwise mode (OpenSSL::SSL::VERIFY_PEER is default)
* rest_options: a hash of options that will be passed on to the rest-client calls. The passed in rest_options will be merged with the standard options that are set (username, password, and verify_ssl). This will allow you to set additional SSL settings. See [the rest-client docs](http://rubydoc.info/gems/rest-client/1.6.7/file/README.rdoc#SSL_Client_Certificates) for more information. Note, the options that you pass in will take precedence over the previous 3 options, so it is possible to set/override the username, password, and verify_ssl options directly with this hash.
* additional_params: a hash of query string params that will be passed on all calls (query, new, update, delete, batch)
* namespace: a string based namespace to create your objects in. You can specify the namespace using periods as separators (like .NET, for example `VisoftInc.Sample.Models`) or using double colons as separators (like Ruby `VisoftInc::Sample::Models`). By providing a namespace you can prevent naming collisions in your applications.

### Adding
When you point at a service, an AddTo<EntityName> method is created for you.  This method takes in the new entity to create.  To commit the change, you need to call the save_changes method on the service.  To add a new category for example, you would simply do the following:

    require 'ruby_odata'

    svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc"
    new_category = Category.new
    new_category.Name = "Sample Category"
    svc.AddToCategories(new_category)
    category = svc.save_changes
    puts category.to_json

### Updating
To update an object, simply pass the modified object to the update_object method on the service. Updating, like adding requires you to call save_changes in order to persist the change.  For example:

    require 'ruby_odata'

    svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc"
    new_category = Category.new
    new_category.Name = "Sample Category"
    svc.AddToCategories(new_category)
    category = svc.save_changes
    puts category.to_json

    category.Name = 'Updated Category'
    svc.update_object(category)
    result = svc.save_changes
    puts "Was the category updated? #{result}"

### Deleting
Deleting an object involves passing the tracked object to the delete_object method on the service.  Deleting is another function that involves the save_changes method (to commit the change back to the server).  In this example, we'll add a category and then delete it.

    require 'ruby_odata'

    svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc"
    new_category = Category.new
    new_category.Name = "Sample Category"
    svc.AddToCategories(new_category)
    category = svc.save_changes
    puts category.to_json

    svc.delete_object(category)
    result = svc.save_changes
    puts "Was the category deleted? #{result}"

### Add Link
Adding a linkage between entities can now be performed outside of creation or modification of the objects. See the [OData documents](http://www.odata.org/developers/protocols/operations#CreatingLinksbetweenEntries) for more details.
To add a link between entities, simply call the `add_link` method on the Service passing the parent object, the name of the navigation property, and the child object. Like all save operations, you need to call `save_changes` to persist the changes.

    svc.add_link(<Parent>, <Navigation Property Name>, <Child>)
    svc.save_changes

### Querying
Querying is easy, for example to pull all the categories from the SampleService, you simply can run:

    require 'ruby_odata'

    svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc"
    svc.Categories
    categories = svc.execute
    puts categories.to_json

You can also expand, add filters, order, skip records, and take only the top X records to the query before executing it.  For example:

### Expanding
Expanding allows you to eagerly load other objects that are children of the root.
You can use more than one expand on a query.
For expanding grandchild and lower entities, you must pass in the full path from the root, for example `Products.expand('Orders').expand('Orders/LineItems')`

    # Without expanding the query
    svc.Products(1)
    prod1 = svc.execute
    puts "Without expanding the query"
    puts "#{prod1.to_json}\n"

    # With expanding the query
    svc.Products(1).expand('Category')
    prod1 = svc.execute
    puts "With expanding the query"
    puts "#{prod1.to_json}\n"

### Lazy Loading
If you want to implement lazy loading, the ruby_odata `Service` allows you to perform this. You simply need to call the `load_property` method on the `Service` passing in the object and the navigation property to fill.

    # Without expanding the query
    svc.Products(1)
    prod1 = svc.execute.first
    puts "#{prod1.to_json}\n"

    # Use load_property for lazy loading
    svc.load_property(prod1, "Category")
    puts "#{prod1.to_json}\n"

### Filtering
The syntax for filtering can be found on the [OData Protocol URI Conventions](http://www.odata.org/developers/protocols/uri-conventions#FilterSystemQueryOption) page.
You can use more than one filter, if you call the filter method multiple times it will before an AND.

    # You can access by ID (but that isn't is a filter)
    # The syntax is just svc.ENTITYNAME(ID) which is shown in the expanding examples above

    svc.Products.filter("Name eq 'Product 2'")
    prod = svc.execute
    puts "Filtering on Name eq 'Product 2'"
    puts "#{prod.to_json}"

Note you can pass more than one filter in the string, for example (querying Netflix):

    svc.Titles.filter("Rating eq 'PG' and ReleaseYear eq 1980")

Filters can also be chained, by doing this you will create an "and" filter (just like the last example) when it is passed to the server.

    svc.Titles.filter("Rating eq 'PG'").filter("ReleaseYear eq 1980")


### Combining Expanding and Filtering
The query operations follow a [fluent interface](http://en.wikipedia.org/wiki/Fluent_interface), although they can be added by themselves as well as chained

    svc.Products.filter("Name eq 'Product 2'").expand("Category")
    prod = svc.execute
    puts "Filtering on Name eq 'Product 2' and expanding"
    puts "#{prod.to_json}"

### Order By
You can order the results by properties of your choice, either ascending or descending.
Order by are similar to `expands` in that you can use more than one of them on a query.
For expanding grandchild and lower entities, you must pass in the full path from the root like would do on an `expand`

    svc.Products.order_by("Name")
    products = svc.execute

    # Specifically requesting descending
    svc.Products.order_by("Name desc")
    products = svc.execute

    # Specifically requesting ascending
    svc.Products.order_by("Name asc")
    products = svc.execute

Like the fiter method, order_by statements can also be chained like so:

    svc.Products.order_by("Name asc").order_by("Price desc")


### Skip
Skip allows you to skip a number of records when querying.  This is often used for paging along with `top`.

    svc.Products.skip(5)
    products = svc.execute # => skips the first 5 items

### Top
Top allows you only retrieve the top X number of records when querying.  This is often used for paging along with `skip`.

    svc.Products.top(5)
    products = svc.execute # => returns only the first 5 items

### Navigation Property Links Only Query
OData allows you to [query navigation properties and only return the links for the entities](http://www.odata.org/developers/protocols/uri-conventions#AddressingLinksBetweenEntries) (instead of the data).
**Note**: You cannot use the `links` method and the `count` method in the same query

    svc.Categories(1).links("Products")
    product_links = svc.execute # => returns URIs for the products under the Category with an ID of 1

### Advanced Navigation Property Functions
There are instances where you may need to navigate down a level in order to form the proper query.
Take for example [Netflix's OData Service](http://developer.netflix.com/docs/oData_Catalog/) and their `Genres` Entity Collection, where you can access a Navigation Property (in this case `Titles` through the `Genre` and filter on it:

    http://odata.netflix.com/Catalog/Genres('Horror%20Movies')/Titles?$filter=Name%20eq'Halloween'

In order to do this within ruby_odata, you can use the `navigate` method of the `QueryBuilder` to drill-down into the Navigation Property. This will allow you to perform `filter`s, `skip`s, `orderby`s, etc. against the children.

    svc = OData::Service.new("http://odata.netflix.com/Catalog")
    svc.Genres("'Horror Movies'").navigate("Titles").filter("Name eq 'Halloween'")
    movies = svc.execute
    movies.each { |m| puts m.Name }

### Count
Sometimes all you want to do is count records, for that, you can use the `count` method.
This method can be combined with other options, such as `filter` but cannot be combined with the `links` method.

    svc.Products.count
    puts svc.execute # => 2

### Partial feeds
OData allows services to do server-side paging in Atom by defining a next link. The default behavior is to repeatedly consume partial feeds until the result set is complete.

    svc.Partials
    results = svc.execute # => retrieves all results in the Partials collection

If desired (e.g., because the result set is too large to fit in memory), explicit traversal of partial results can be requested via options:

    svc = OData::Service.new "http://example.com/Example.svc", { :eager_partial => false }
    svc.Partials
    results = svc.execute # => retrieves the first set of results returned by the server
    if svc.partial? # => true if the last result set was a partial result set (i.e., had a next link)
      results.concat svc.next # => retrieves the next set of results
    end
    while svc.partial? # => to retrieve all partial result sets
      results.concat svc.next
    end

### Authentication
Basic HTTP Authentication is supported via sending a username and password as service constructor arguments:

    require 'ruby_odata'

    svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc", { :username => "bob", :password=> "12345" }

NTLM authentication is also possible. Faraday lacks documentation how to use NTLM, even though multiple backends support it. Therefore, it is unclear what is the best way to achieve NTLM authentication, but a possibility is shown below.

    require 'ruby_odata'
    require 'httpclient'

    class ConfigurableHTTPClient < Faraday::Adapter::HTTPClient
      def initialize(*, &block)
        @block = block
        super
      end

      def call(env)
        @block.call self if @block
        super
      end
    end
    Faraday::Adapter.register_middleware(configurable_httpclient: ConfigurableHTTPClient)

    url = "http://127.0.0.1:8989/SampleService/RubyOData.svc"
    svc = OData::Service.new url do |faraday|
      faraday.adapter(:configurable_httpclient) { |a| a.client.set_auth url, "bob", "12345" }
    end

### SSL/https Certificate Verification
The certificate verification mode can be passed in the options hash via the :verify_ssl key. For example, to ignore verification in order to use a self-signed certificate:

    require 'ruby_odata'

    svc = OData::Service.new "https://127.0.0.1:44300/SampleService/RubyOData.svc", { :verify_ssl => false }

Or an OpenSSL integer constant can be passed as well:

    require 'ruby_odata'

    svc = OData::Service.new "https://127.0.0.1:44300/SampleService/RubyOData.svc", { :verify_ssl => OpenSSL::SSL::VERIFY_PEER }

Default verification is OpenSSL::SSL::VERIFY_PEER. Note due to the way Ruby's Request object implements certificate checking, you CAN NOT pass OpenSSL::SSL::VERIFY_NONE, you must instead pass a boolean false.

## Function Imports / Custom Service Methods
Function Imports are custom service methods exposed by the WCF Data Service. Each function import will be created as a method on the ruby_odata Service. When you make a call to one of these, they return a result immediately without the need to call `execute` or `save_changes`.

## Reflection
Instead of relying on looking at the EDMX directly, ruby_odata allows you to perform basic reflection on objects
### Service Level Methods
* **Collections** - You can look at the collections exposed by a service by accessing the `collections` method, which is a hash. The key is the name of the collection and the value is the hash with `edmx_type`, which returns the name of the type from the EDMX and `:type`, which is the local type that is created for you
* **Classes** - To see the generated classes, you can utilize the `classes` method on the service. The return result is a hash where the key is the class name and the value is the class type.
* **Function Imports** - You can find any function import (custom service methods) exposed by the service by accessing the `function_imports` method. This is a hash where the key is the Function Import name and the value is metadata about the Function Import.

### Class Level Methods
* **Properties** - You can call the class method `properties` on a generated class to see the method (properties) that were created. The returned result is a hash where the key is the property name and the value is metadata for the property like if it is nullable, the EDM Type, etc.

## Tests
All of the tests are written using Cucumber going against a sample service (Found in test/RubyODataService/RubyODataService/*).
The SampleService is an ASP.NET Web Site running a SQL Compact 4 Database, which gets generated at runtime, as well as the ADO.NET Entity Framework 4.1 and WCF Data Services October 2011 CTP. The reason for the CTP is that WCF Data Services currently shipping with .NET 4 doesn't support Entity Framework 4.1's "Code First" approach (e.g. no EDMX, all POCOs)
In order to run the tests, you need to spin up IIS running a virtual directory of SampleService on port 8989 (http://localhost:8989/SampleService) and another instance running on port 44300.

**NOTE** The ports (8989 and 44300) and webserver (localhost by default) here are customizable thanks to `/features/contants.rb`. Take a look in there for the corresponding environment variables that you can set.

The SampleService requires IIS or IIS Express. IIS Express is a free download from Microsoft and the preferred approach to running the application. Once installed, there is a batch file found in /test called "iisExpress x64.bat" that will spin up the appropriate instances needed for the Cucumber tests. There is a also an "iisExpress x86.bat" file for those of you running a 32-bit machine.  The only difference is the path to the Program Files directory.  Once you run the batch file, the web server will spin up.  To stop the server, use 'Q' and then enter or close the command window.

If you are having trouble with IIS Express, you may need to perform the following: Upon running the IIS Express installer copy the config folder from the IIS Express installed folder (e.g. c:\Progam Files (x86)\IIS Express\config) to the IIS folder in your home folder (e.g. c:\Users\Administrator\Documents\IISExpress). Within the newly copied config folder, copy the aspnet.config file from the templates\PersonalWebServer\aspnet.config folder into the config folder as well (e.g. c:\Users\Administrator\Documents\IISExpres\config\aspnet.config).

If you are testing on a Windows machine, you may encounter a problem with using Cucumber and Ruby 1.9.2.  You will get a message when you fire up cucumber about missing msvcrt-ruby18.dll.  The fix for this is to make sure you have the [RubyInstaller DevKit](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit) installed, then do the following:

    gem uninstall json
    gem install json --platform=ruby -v 1.4.6

Once the SampleService is running, from the BASE ruby_odata directory, simply type `rake`, which will run the RSpec and Cucumber specs. You can also run them separately `rake spec` for RSpec and `rake features` for Cucumber.

