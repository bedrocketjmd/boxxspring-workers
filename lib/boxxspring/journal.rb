module Boxxspring

  class Journal

    def initialize( name )
      @db_name = name
    end

    def write( id, attributes )
      db_attributes = []
      attributes.each_pair do | key, value |
        db_attributes.push( { 
          name: key.to_s, value: value.to_s, replace: true
        } )
      end
      self.db.put_attributes( {
        domain_name: @db_name,
        item_name: id.to_s,
        attributes: db_attributes 
      } )
    end
    
    def read( id )
      result = nil
      db_record = self.db.get_attributes(
        domain_name:      @db_name,
        item_name:        id.to_s,
        consistent_read:  true
      )
      if db_record.present? && 
         db_record.attributes.present? &&
         db_record.attributes.length > 0 
        result = {}
        db_record.attributes.each do | attribute |
          result[ attribute.name.to_sym ] =  attribute.value
        end
      end
      result
    end

    protected; def db 
      @db ||= begin 
        db = Aws::SimpleDB::Client.new
        db.create_domain(
          domain_name: @db_name
        )
        db
      end    
    end

  end

end