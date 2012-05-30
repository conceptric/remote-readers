require File.join(File.dirname(__FILE__), *%w[spec_helper.rb])
XML_FIXTURES = File.join(File.dirname(__FILE__), *%w[fixtures xml])

module XmlTestHelpers
  def fixture_stream_helper(filename)
    StringIO.new(File.read(File.join(XML_FIXTURES, filename)))
  end

  def xml_stub(filename)
    xml_file = open(XML_FIXTURES + '/' + filename)
    Remote::Xml::Reader.stub(:open).and_return(xml_file)            
  end

  def remote_reader_factory(filename)
    xml_stub(filename)
    Remote::Xml::Reader.new('remote_url')
  end
end  

describe Remote::Xml::Reader do
  include XmlTestHelpers
  
  describe "Remote::Xml::Reader.open" do
    
    context "a remote url that exists" do
      it "opens a remote url" do
        test_url = 'http://www.example.com/example.xml'

        Remote::Xml::Reader.should_receive(:open).
        once.
        with(test_url).
        and_return(
          fixture_stream_helper('single_node.xml'))

        Remote::Xml::Reader.open(test_url).read.
            should == open(XML_FIXTURES + '/single_node.xml').read  
      end
      
      it "opens the remote url to a blank document" do
        Remote::Xml::Reader.should_receive(:open).
        and_return(
          fixture_stream_helper('blank_document.xml'))

        expect { Remote::Xml::Reader.open('blank') }.
          should_not raise_error
      end
      
      it "opens a real url" do
        expect {Remote::Xml::Reader.open('http://www.job-tv.co.uk/XML.asp')}.
        should_not raise_error
      end
    end

    context "a remote url that does not exist" do
      it "raises an exception with a message about the invalid url" do
        expect { Remote::Xml::Reader.open('invalid') }.
          to raise_error(ArgumentError, "This URI is invalid")
      end

      it "raises an exception with a message about a nil url" do
        expect { Remote::Xml::Reader.open(nil) }.
          to raise_error(ArgumentError, "A URI is required")
      end

      it "raises an exception with a message about a blank url" do
        expect { Remote::Xml::Reader.open('') }.
          to raise_error(ArgumentError, "This URI is invalid")
      end
    end
    
  end  

  describe ".new" do      
    
    shared_examples "a new XML Reader" do |example_xml_file|      
      it "creates a new instance" do
        xml_stub(example_xml_file)
        Remote::Xml::Reader.new('remote_url').
          should be_instance_of(Remote::Xml::Reader)      
      end        

      it "that contains the target xml" do
        xml_stub(example_xml_file)
        xml_file = open(XML_FIXTURES + '/' + example_xml_file)
        Remote::Xml::Reader.new('remote_url').read.
          should == xml_file.read
      end
    end
    
    context "given a remote url to valid xml" do
      include_examples "a new XML Reader", 'single_node.xml'
    end
    
    context "given a remote url to empty xml" do
      include_examples "a new XML Reader", 'blank_document.xml'
    end

    context "given a remote url to an empty file" do
      include_examples "a new XML Reader", 'empty.xml'
    end
  end

  describe ".children_of_named_node" do
    
    def remote_reader_setup(filename)
      remote_reader_factory(filename).children_of_named_node('jobs')      
    end                                               
    
    context "given a file with valid xml" do
      before(:each) do
        @result = remote_reader_setup('/twin_node.xml')
      end
  
      it "returns an array containing matching nodes" do
        @result.size.should == 2
      end                                                        
    
      it "each of these data nodes are Nokogiri elements" do
        @result.each do |item|
          item.should be_instance_of(Nokogiri::XML::Element)
        end
      end
  
      it "each element contains the correct amount of data" do
        @result.each do |item|                     
          item.children.count.should == 5
        end
      end
  
      it "each element contains the correct data" do
        @result.each do |item|
          item.node_name == "item"
          item.first_element_child.node_name.should == 'child1'
          item.last_element_child.node_name.should == 'child2'
        end
      end
    end
    
    context "given a blank xml file" do
      it "returns an empty array" do
        remote_reader_setup('blank_document.xml').
          should == []
      end             
    end

    context "given a completely empty file" do
      it "returns an empty array" do
        remote_reader_setup('empty.xml').
          should == []
      end             
    end

    context "given complex xml with named elements nested" do
      it "returns an array named elements recursively" do
        remote_reader_setup('complex_node.xml').size.
          should == 5
      end             
    end
    
  end 
  
  describe ".child_nodes_to_hash" do
  
    def hash_reader_setup(filename)
      remote_reader_factory(filename).child_nodes_to_hash("jobs")
    end
        
    context "given an array of valid nokogiri nodes" do
      it "converts the children of a named node to a hash" do 
        result = hash_reader_setup('single_node.xml')
        result.should == [{child1: "value1", child2: "value2"}]
      end

      it "converts the children of two named node to a hashes" do 
        result = hash_reader_setup('twin_node.xml')
        result.should == [
          {child1: "value1", child2: "value2"},
          {child1: "value1", child2: "value2"}]
      end

      it "includes CDATA with special formatting characters" do 
        result = hash_reader_setup('complex_node.xml')
        result.should include(
          { child1: "value1", 
            child2: "CDATA is included\nwith special characters" }        
        )
      end                                 
    end
                                    
    context "given an array of nodes with nested elements" do
       it "ignores nested elements within each child" do 
         result = hash_reader_setup('complex_node.xml')
         result.should_not include(
           { subchild1: "should be ignored", 
             subchild2: "should be ignored" })
       end                           
       
       it "ignores child nodes with no elements" do
         result = hash_reader_setup('complex_node.xml')
         result.should_not include('This is not a valid child node')
         result.should_not include({})
         result.size.should == 4
       end                                     
       
       it "includes the children of nested parents" do
         result = hash_reader_setup('complex_node.xml')
         result.should include(
           { child1: "should be included", 
             child2: "should be included" })         
       end       
    end    
  end
  
end
  
