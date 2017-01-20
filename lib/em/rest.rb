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
      
      def exec(arguments)
        
        httpVerb = arguments[:httpVerb]
        httpUrl = arguments[:httpUrl]
        bodyReq = arguments[:bodyReq]
        arguments = {endUrlParams: true}.merge(arguments)
        
        resUrl = httpUrl.split('/')
        resUrl.shift
        
        args = { httpVerb: httpVerb,
                 httpUrl: httpUrl,
                 bodyReq: bodyReq,
                 resUrl: resUrl,
                 urlParams: resUrl.clone() }
        
        resObj = @resources
        
        lastIndex = resUrl.size - 1
        resUrl.each_index  do |i|
          method = resUrl[i]
          nameHandler = "handler#{method.to_s.capitalize}".to_sym
          
          params = []
                    
          args[:i] = i
          args[:urlParams].shift
            
          if ( httpVerb == 'POST' or httpVerb == 'PUT' ) and i == lastIndex
            params = args[:bodyReq]
          end
         
          if resObj.respond_to?:call
            if params.is_a?Array
              resObj = resObj.call(@resources,args)
            else
              resObj = resObj.call(@resources,args)
            end
          elsif resObj.respond_to?method.to_sym
            if params.is_a?Array
              resObj = resObj.send(method.to_sym,*params)
            else
              resObj = resObj.send(method.to_sym,params)
            end
          elsif resObj.respond_to?nameHandler
            resObj = resObj.send(nameHandler,args)
          else # no method on resource 
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
              
            else # no key as method
                            
              methodHandled = false
                        
#              if !@customHandler.nil? and @customHandler.respond_to?:call
#                methodHandled = true
#                resObj = @customHandler.call(@resources,args)
#              elsif !@customHandler.nil? and @customHandler.respond_to?method.to_sym
#                methodHandled = true
#                resObj = @customHandler.send(method.to_sym,@resources,args)
#              elsif !@customHandler.nil? and @customHandler.respond_to?:key
#                if @customHandler.key?method
#                  custMeth = @customHandler[method]
#                  if custMeth.respond_to?:call
#                    methodHandled = true
#                    resObj = custMeth.call(@resources,args)
#                  end
#                elsif @customHandler.key?method.to_sym
#                  custMeth = @customHandler[method.to_sym]
#                  if custMeth.respond_to?:call
#                    methodHandled = true
#                    resObj = custMeth.call(@resources,args)
#                  end
#                end 
#              end 
              
              unless methodHandled
                
                if resObj.respond_to?:method_missing
                  resObj = resObj.send(method,args)
                else 
                  raise TargetResourcesException.new("Resource [#{method}] Not Found")
                end
              
              end
                  
            end
            
          end
          
          return resObj if arguments[:endUrlParams]
          
        end ## end loop on chunk url method
        
        resObj
      end
      
    end
  
    class TargetResourcesException < StandardError
      def initialize(msg="Exception on target resouces")
        super
      end
    end
  
  end
  
end
