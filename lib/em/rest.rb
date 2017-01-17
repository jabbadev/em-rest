require 'eventmachine'
require "em/rest/version"

module EventMachine
  module Rest
    
    class Connection < EventMachine::Connection
      def initialize(resources,getHandler=nil)
         @target = TargetResouces.new(resources,customHandler)
      end
    end
    
    class TargetResources
      
      def initialize(resources,customHandler=nil)
        @resources = resources
        @customHandler = customHandler
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
              
              urlParams = resUrl.clone()
              urlParams.slice!(0)
              args = { httpVerb: httpVerb,
                       httpUrl: httpUrl,
                       bodyReq: bodyReq,
                       resUrl: resUrl,
                       i: i,
                       urlParams: urlParams }
                       
              if !@customHandler.nil? and @customHandler.respond_to?:call
                return @customHandler.call(@resources,args)
              elsif !@customHandler.nil? and @customHandler.respond_to?method.to_sym
                return @customHandler.send(method.to_sym,@resources,args)
              elsif !@customHandler.nil? and @customHandler.respond_to?:key
                if @customHandler.key?method
                  custMeth = @customHandler[method]
                  if custMeth.respond_to?:call
                    return custMeth.call(@resources,args)
                  end
                elsif @customHandler.key?method.to_sym
                  custMeth = @customHandler[method.to_sym]
                  if custMeth.respond_to?:call
                    return custMeth.call(@resources,args)
                  end
                end 
              else 
              
                nameHandler = "handler#{method.to_s.capitalize}".to_sym
              
                if resObj.respond_to?nameHandler
                  return resObj.send(nameHandler,args)
                end
              
                if resObj.respond_to?:method_missing
                  return resObj.send(method,args)
                else 
                  raise TargetResourcesException.new("Resource Not Found")
                end
              
              end
            end
          end
          
        end
        
        resObj
        
      end
       
      
    end
  end
  
  class TargetResourcesException < StandardError
    def initialize(msg="Exception on target resouces")
      super
    end
  end
  
end
