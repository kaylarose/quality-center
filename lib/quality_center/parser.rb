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
    # TODO support query params
    def defects
      @defects ||= Nokogiri::XML.parse(@connection.defects).
                     css('Entity').
                     map{|defect| defect_to_hash(defect)}
    end

    # A map from machine-readable field names to human-readable labels.
    def defect_fields
      @defect_fields ||= entities_to_hash( Nokogiri::XML.parse @connection.defect_fields )
    end

    # A map from user logins to full names.
    # TODO embed extra data.
    def users
      @users ||= entities_to_hash( Nokogiri::XML.parse(@connection.users), 
                                   entity_name: 'User',
                                   value_field: 'FullName',
                                   key_process: :downcase )
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



  end
end
