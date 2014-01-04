# template substitution
# reference:  http://freecode.com/articles/templates-in-ruby
#
# TODO seems like too much memory copying, but works.  Review later
#
module PBManager
  class TSub

    # load the template
    def initialize( template )
      @template = template.clone()
      @replaceStrs = {}
    end

    # set the delimiter and the values (hash or string)
    def set( replaceStr, values )
      (values.kind_of?(Hash)) ?
          @replaceStrs[replaceStr] = values.method(:fetch) :
          @replaceStrs[replaceStr] = values.clone()
    end

    # take the templace and replace the 'delimited' token all replacement values
    def run()
      outStr = @template.clone()
      @replaceStrs.keys.each { |replaceStr|
         outStr.gsub!( /#{replaceStr}(.*?)#{replaceStr}/ ) {
         @replaceStrs[ replaceStr ].call( $1 ).to_s
        }
      }
      outStr
    end

    # was hoping this would work
    def
      to_s() run();
    end

  end
end