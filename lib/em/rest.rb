require 'eventmachine'
require "em/rest/version"

module EventMachine
  module Rest
    #class Server < EventMachine::Connection
    class Server
      
      def initialize(resources)
        @resources = {}
        unless resources.empty?
          resources.each do|key,res|
            res[:opt] = {} unless res.key?:opt
            @resources[key.to_sym] = res 
          end
        end
      end
      
      def exec(res,param)
        
        res = res.to_sym
        unless @resources.key?res
          raise Exception.new("resource found")
        end
        
        resObj = @resources[res][:res]
        
        if resObj.respond_to?:call
          return resObj.call(param)
        end
        
        if resObj.respond_to?:send
          method = param.slice!(0)
          p method
          p param
          return resObj.send(method,*param)
        end
         
      end
      
      
    end
  end
end
