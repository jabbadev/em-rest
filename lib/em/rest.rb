require 'eventmachine'
require "em/rest/version"

module EventMachine
  module Rest
    #class Server < EventMachine::Connection
    class Server
      
      def initialize(resources)
        @resources = resources
      end
      
      def exec(httpVerb,httpUrl,bodyReq=nil)
        
        resUrl = httpUrl.split('/')
        resUrl.slice!(0)
        
        resObj = @resources
        
        lastIndex = resUrl.size - 1
        resUrl.each_index  do |i|
          method = resUrl[i]
          params = []
          
          if httpVerb == "POST" or httpVerb == "PUT"
            if (lastIndex == i )
              params = JSON.load(bodyReq) unless bodyReq.nil?
            end
          end
           
          if resObj.respond_to?:call
            if params.is_a?Array
              resObj = resObj.call(*params)
            else
              resObj = resObj.call(params)
            end
          elsif resObj.respond_to?method.to_sym
            if params.is_a?Array
              resObj = resObj.send(method,*params)
            else
              resObj = resObj.send(method,*params)
            end
          else
            if resObj.respond_to?:key
              
              if resObj.key?method
                obj = resObj[method]
              elsif resObj.key?method.to_sym
                obj = resObj[method.to_sym]
              end
              
              if obj.respond_to?:call
                if params.is_a?Array
                  resObj = obj.call(*params)
                else
                  resObj = obj.call(params)
                end
              else
                resObj = obj
              end
              
            else
               p "resource not found ..."
            end
          end
          
        end
        
        resObj
        
      end
       
      
    end
  end
end
