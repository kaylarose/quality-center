require 'nokogiri'
require 'active_support/core_ext/hash'
require_relative 'constants'

# A class to make QC's responses a little more usable.  
# The primary method is #defects, which returns an array of defect hashes.
# TODO split Defect into another class.
module QualityCenter
  class Parser

    # Create the object with mock => true to enable fake API calls.
    #
    # connection - ::RemoteInterface::Rest object to handle requests.
    # mock       - Boolean, indicates whether to use a fake connection object
    #              for testing or development purposes.
    # Example
    #
    #   Parser.new(connection: ::RemoteInterface::Rest.new)
    #   Parser.new(mock: true)
    def initialize(opts={})
      @conn = if opts[:mock]
        require_relative 'remote_interface/mocks'
        RemoteInterface::Mocks::Rest.new
      else
        opts[:connection]
      end
      raise ArgumentError 'invalid connection' unless @conn.respond_to? :login
    end

    # A list of defects.  You can pass in Query objects or
    # anything else that the @conn object understands.
    #
    # query - A ::RemoteInterface::Query or a Hash to filter the results.
    #
    # Example
    #
    #   defects(:query => ::RemoteInterface::Query.new.filter(id:'<9') )
    #
    # Returns an Array of Hashes representing individual defects.
    def defects(opts={})
      opts.merge!(raw:true)
      @defects ||= Nokogiri::XML.parse( @conn.defects(opts) ).
                     css('Entity').
                     map{|defect| defect_to_hash(defect)}
    end

    # A map from machine-readable field names to human-readable labels.
    #
    # Returns a Hash like {'user-06'=>'Environment", 'user-01'=> 'External ID'}
    def defect_fields
      @defect_fields ||= response_to_hash( @conn.defect_fields )
    end

    # A map from user logins to full names.
    #
    # Returns a Hash like  {bob: "Bob Smith",john: "John Doe"}
    def users
      @users ||= response_to_hash( @conn.users,
                                   entity_name: 'User',
                                   value_field: 'FullName',
                                   key_process: :downcase )
    end

    # Hash of the root object.  Not that useful, possibly not working.
    #
    # Returns a hash of something or other.
    def root
      ret = {}
      xml = Nokogiri::XML.parse(@conn.auth_get(''))
      xml.css('ns2|workspace').each do |workspace|
        ret[workspace.css('title').first.text] = 
          Hash[
            workspace.css('ns2|collection').map{|x| [x.text,x.attributes['href'].value] }
          ]
      end
      ret
    end

    private 

    # Get the value of the Name attribute for a field
    # 
    # node           - the XML Node to grab the attribute from.
    # name_attribute - the XML attribute representing the node's name.  
    #                  Defaults to 'Name'.
    #
    # Returns a String representing the "Name" of the XML node.
    def attr(node,name_attribute='Name')
      node.attributes[name_attribute].value
    end

    # Get the display-friendly name of a field.
    # Relies on the #defect_fields method to provide nice names.
    #
    # field - the XML Node to grab the name from.
    def nice_name(node)
      name = attr(node)
      defect_fields[name] || name
    end

    # get the value of the field, converting things like dates and user names
    def value(field)
      if DATE_FIELDS.include? (name=attr(field))
        Time.parse(field.text) rescue field.text
      elsif USER_FIELDS.include? name
        users[field.text.downcase]
      else
        field.text
      end
    end

    # Convert a single defect entity into a hash.
    # Ignores fields with empty values.
    #
    # Example
    #
    #   xml =  <Entity Type="defect">
    #            <Fields>
    #              <Field Name="a">
    #                <Value>1</Value>
    #              </Field>
    #              <Field Name="b">
    #                <Value>2</Value>
    #              </Field>
    #              <Field Name="c">
    #                <Value></Value>
    #              </Field>
    #            </Fields>
    #          </Entity>
    #
    #   defect_to_hash(xml)
    #   # => {a:1, b:2}
    # 
    # Returns a Hash representing a defect.
    def xml_defect_to_hash(xml)
      defect={}
      xml.css('Field').each do |field|
        unless (text=field.text).empty? or text == 'None'
          defect[ nice_name(field) ] = value(field)
        end
      end
      defect
    end
   
    def defect_to_hash(input)
      Hash[ input["Fields"]["Field"].
            map{    |x| [nice_name[x["Name"]],x["Value"]] }.
            reject{ |x,y| y.empty? or y == "None" }
          ]
    end


    # Generic function to turn a QC entity list into a simple hash.
    #
    #   doc         - A Nokogiri::XML::Document from QC.
    #   entity_name - The XML tag name of each entity in the list.
    #   value_field - The XML attribute that constitutes the "value" of an entity.
    #   key_process - The name of a transform method to apply to keys.
    #   val_process - Like key_process for values.
    #
    # Examples
    # 
    #   doc = <Users>
    #           <User Name="BoB"  FullName="Bob Smith"/>
    #           <User Name="john" FullName="John Doe"/>
    #         </Users>
    #
    #   opts = {entity_name: 'User', value_field: 'FullName'}
    #
    #   entities_to_hash(doc, opts)
    #   # => {BoB: "Bob Smith", john: "John Doe"}
    #
    #   entities_to_hash(doc, opts.merge(key_process: :downcase)
    #   # => {bob: "Bob Smith", john: "John Doe"}
    #
    #   entities_to_hash(doc, opts.merge(val_process: :upcase)
    #   # => {BoB: "BOB SMITH",john: "JOHN DOE"}
    #
    # Returns a Hash extracted from the entity list mapping one attribute to another.
    def entities_to_hash(doc,opts={})
      # apply defaults over missing options
      opts.reverse_merge!(entity_name: 'Field',
                          value_field: 'Label',
                          key_process: nil,
                          val_process: nil)
      entities = Hash[]
      doc.css(opts[:entity_name]).each do |entity|
      
        # Get the key for this entity, optionally postprocessing it
        key = attr(entity)
        if opts[:key_process]
          key = key.send(opts[:key_process])
        end
        
        # Get the value, postprocess it, and discard if empty
        value = attr(entity,opts[:value_field])
        value = key if value.empty?
        if opts[:val_process]
          value = value.send(opts[:val_process])
        end

        entities[key] = value
      end
      entities
    end

    # Simple function to get from the root of a QC entity list to the meat.
    # TODO use a better pluralizer.
    # 
    # in_hash     - Hash of form:
    #                 {Somethings:{Something:[MEAT]}}.
    #               This is likely produced by HTTParty's built in parser.
    # entity_name - String, "Something" in the above example.
    #
    # Returns an array of entities if called on the expected kind of hash.
    def collection(in_hash,entity_name)
      puts in_hash.inspect
      in_hash[entity_name+'s'][entity_name]
    end

    def response_to_hash(response,opts={})
      opts.reverse_merge!(entity_name: 'Field',
                          key_field:   'Name',
                          value_field: 'Label',
                          key_process: :to_s,
                          val_process: :to_s)

      root = collection(response,opts[:entity_name])

      Hash[ root.map{ |entity|
                      [
                        entity[opts[:key_field]].  send(opts[:key_process]),
                        entity[opts[:value_field]].send(opts[:val_process])
                      ]
                    } 
          ]
    end

  end
end
