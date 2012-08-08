require 'libxml'
require 'xmlsimple'

class VoxelHAPIResponse
  exceptions :argument, :parsing
  
  attr_accessor :debug
  attr_reader :raw_xml, :raw_hash
  
  def initialize( options = {} )
    options.reverse_merge! :debug => false
    raise Argument, ":raw_xml is a required option" unless options.has_key?(:raw_xml)
    
    @raw_hash = nil
    @raw_xml  = options[:raw_xml]
    @debug    = options[:debug]
  end
  
  def to_xml
    raw_xml
  end
  
  def to_h(options = {})
    process_xml_document(@raw_xml, options)
  end
  
private
  
  def process_xml_node( node )
    node_hash = Hash.new
    node_name = node.name
    
    node.attributes.each { |attr| node_hash[attr.name] = attr.value }
    
    if node.children? and node.first.name != 'text'
      node.each_child do |child|
        if node_hash.has_key?(child.name)
          unless node_hash[child.name].is_a?(Array)
            tmp_node = node_hash[child.name]
            node_hash[child.name] = [ tmp_node ]
          end
          
          node_hash[child.name].push(process_xml_node(child))
        else
          node_hash[child.name] = process_xml_node(child)
        end
      end
      
      node_hash
    else
      node_hash['content'] = node.content
      node_hash
    end
  end
  
  def process_xml_document_new( xml_data )
    document = LibXML::XML::Parser.string(xml_data).parse
    document_hash = {}
    
    STDERR.puts document.to_s if @debug
    
    document.root.attributes.each { |attr| document_hash[attr.name] = attr.value }
    
    document.root.each do |node|
      document_hash[node.name] = process_xml_node(node)
    end
    
    document_hash
  end
  
  def process_xml_document( xml_data, options = {} )
    options.reverse_merge! 'ForceArray' => false
    XmlSimple.xml_in(xml_data, options)
  end
end