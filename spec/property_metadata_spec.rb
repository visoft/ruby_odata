require 'spec_helper'

module OData
  describe PropertyMetadata do
    describe "#initialize" do
      it "parses an EDMX property with the essentials (name, type, nullable)" do        
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Id" Type="Edm.String" Nullable="false" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.name.should eq "Id"
        property_metadata.type.should eq "Edm.String"
        property_metadata.nullable.should eq false
      end
      it "parses an EDMX property where nullable is true" do
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Id" Type="Edm.String" Nullable="true" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.nullable.should eq true
      end      
      it "parses an EDMX property with nil for missing attributes" do        
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Id" Type="Edm.String" Nullable="false" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.fc_target_path.should be_nil
        property_metadata.fc_keep_in_content.should be_nil
      end
      it "parses an EDMX property with false for missing Nullable attribute" do        
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Id" Type="Edm.String" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.nullable.should eq false
      end      
      it "parses an EDMX property with the fc_target_path and fc_keep_in_content attribute" do        
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Title" Type="Edm.String" Nullable="true" m:FC_TargetPath="SyndicationTitle" m:FC_ContentKind="text" m:FC_KeepInContent="false" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.fc_target_path.should eq "SyndicationTitle"
        property_metadata.fc_keep_in_content.should eq false
      end
      it "parses an EDMX property where fc_keep_in_content is true" do        
        property_element = RSpecSupport::ElementHelpers.string_to_element('<Property Name="Title" Type="Edm.String" Nullable="true" m:FC_TargetPath="SyndicationTitle" m:FC_ContentKind="text" m:FC_KeepInContent="true" />')
        property_metadata = PropertyMetadata.new property_element
        property_metadata.fc_keep_in_content.should eq true
      end      
    end
  end
end