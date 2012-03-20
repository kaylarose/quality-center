require 'nokogiri'

module QualityCenter

  class Parser
    DATE_FIELDS = %w[closing-date creation-time last-modified]
    USER_FIELDS = %w[detected-by owner]

    # get the value of the Name attribute for a field
    def name(field)
      field.attributes['Name'].value
    end

    def nice_name(field)
      name = name(field)
      defect_fields[name] || name
    end

    def users
      return @users if @users
      usernames={}
      doc = Nokogiri::XML.parse(File.read '/home/brasca/git/qc_rest/fixtures/users.xml')
      doc.css('User').each do |user|
        short = name(user)
        full  = user.attributes['FullName'].value
        usernames[ name(user).downcase ] = full.empty? ? short : full
      end
      usernames
    end

    def defect_fields
      return @defect_fields if @defect_fields
      fields={}
      doc = Nokogiri::XML.parse(File.read '/home/brasca/git/qc_rest/fixtures/defect_fields.xml')
      doc.css('Field').each do |field|
        fields[ name(field) ] = field.attributes['Label'].value
      end
      fields
    end

    # get the value of the field, converting things like dates and user names
    def value(field)
      if DATE_FIELDS.include? (name=name(field))
        Time.parse(field.text) rescue field.text
      elsif USER_FIELDS.include? name
        users[field.text.downcase]
      else
        field.text
      end
    end

    # convert a single defect xml fragement into a hash
    def defect_to_hash(xml)
      defect={}
      xml.css('Field').each do |field|
        unless (text=field.text).empty?
          defect[ nice_name(field) ] = value(field)
        end
      end
      defect
    end

    def defects
      dxml = Nokogiri::XML.parse(File.read '/home/brasca/git/qc_rest/fixtures/defects.xml')
      dxml.css('Entity').map{|defect| defect_to_hash(defect)}
    end


  end
end
