module Boxxspring

  module Synchronization 

    class Configuration 

      include Singleton

      def self.field( field_name, options = {} )

        class_eval(
          "def #{field_name}( *arguments ); " +
             "@#{field_name} = arguments.first unless arguments.empty?; " +
             "@#{field_name} || " +
               ( options[ :default ].blank? ?
                  "nil" :
                  ( options[ :default ].is_a?( String ) ? 
                      "'#{options[ :default ]}'" : 
                        "#{options[ :default ]}" ) ) + ";" +
          "end",
          __FILE__, 
          __LINE__
        )

      end

      field :url,         default: "redis://127.0.0.1:6379/0"

    end

  end
end