require 'nokogiri'
require 'active_support/core_ext/hash'
require_relative 'constants'

module QualityCenter
  class Parser

    # Create the object with mock => true to enable fake API calls
    def initialize(connection,opts={})
      @connection = if opts[:mock]
        require_relative 'remote_interface/mocks'
        RemoteInterface::Mocks::Rest.new
      else
        connection
      end
    end

    # A list of defects.
    def defects(opts={})
      opts.merge!(raw:true)
      @defects ||= Nokogiri::XML.parse( @connection.defects(opts) ).
                     css('Entity').
                     map{|defect| defect_to_hash(defect)}
    end

    # A map from machine-readable field names to human-readable labels.
    def defect_fields
      @defect_fields ||= response_to_hash( @connection.defect_fields )
    end

    # A map from user logins to full names.
    def users
      @users ||= response_to_hash( @connection.users,
                                   entity_name: 'User',
                                   value_field: 'FullName',
                                   key_process: :downcase )
    end

    # Hash of the root object
    def root
      ret = {}
      xml = Nokogiri::XML.parse(@connection.auth_get(''))
      xml.css('ns2|workspace').each do |workspace|
        ret[workspace.css('title').first.text] = 
          Hash[
            workspace.css('ns2|collection').map{|x| [x.text,x.attributes['href'].value] }
          ]
      end
      ret
    end

    private 

    # get the value of the Name attribute for a field
    def attr(field,attr='Name')
      field.attributes[attr].value
    end

    # Get the display-friendly name of a field.
    def nice_name(field)
      name = attr(field)
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
    # Example:
    #   Input  <Entity Type="defect">
    #            <Fields>
    #              <Field Name="a">
    #                <Value>1</Value>
    #              </Field>
    #              <Field Name="b">
    #                <Value>2</Value>
    #              </Field>
    #            </Fields>
    #          </Entity>
    #
    #  Output {a:1,b:2}
    def defect_to_hash(xml)
      defect={}
      xml.css('Field').each do |field|
        unless (text=field.text).empty? or text == 'None'
          defect[ nice_name(field) ] = value(field)
        end
      end
      defect
    end

    # Generic function to turn a QC entity list into a simple hash.
    # Accepts a Nokogiri::XML::Document and the following options:
    #   entity_name: The XML tag name of each entity in the list.
    #                In the below example, 'User'
    #   value_field: The XML attribute that constitutes the "value" of an entity.
    #                For example, 'FullName'
    #   key_process: The name of a transform method to apply to keys.
    #                In the below example, using :downcase would yield
    #                  {bob: "Bob Smith",john: "John Doe"}
    #   val_process: Like key_process for values.
    #                In the below example, using :upcase would yield
    #                  {BoB: "BOB SMITH",john: "JOHN DOE"}
    # Example document:       
    #  <Users>
    #    <User Name="BoB"  FullName="Bob Smith"/>
    #    <User Name="john" FullName="John Doe"/>
    #  </Users>
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
