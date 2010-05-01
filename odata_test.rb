#require 'rubygems'
#require 'open-uri'
#require 'nokogiri'
#
#uri = "http://localhost:2301/Services/Entities.svc/TempAccounts"
#document = Nokogiri::XML(open(uri))
#
#
#
## puts document
##
## puts plans.root.xpath("//d:Name")
#
#
#def get_properties(doc)
#	entries = doc.xpath("//atom:entry[1]",
#                      "atom" => "http://www.w3.org/2005/Atom")
#	props = entries.xpath("//m:properties/*")
#	properties = []
#
#	for prop in props
#		name = prop.name
#		type = prop['type'] || 'Edm.String'
#		prop_obj = Hash[name => type]
#		properties << prop_obj
#	end
#	properties.each do |p|
#		p.collect { |k,v| puts "#{k}: #{v}" }
#	end
#end
#
#get_properties(document)

