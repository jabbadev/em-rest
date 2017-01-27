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
        reqParams = arguments[:reqParams]
        arguments = {endUrlParams: true,convertNumbers: true}.merge(arguments)
        
        resUrl = httpUrl.split('/')
        resUrl.shift
        
        args = { httpVerb: httpVerb,
                 httpUrl: httpUrl,
                 reqParams: reqParams,
                 resUrl: resUrl,
                 urlParams: resUrl.clone() }
        
        resObj = @resources
        
        lastIndex = resUrl.size - 1
        resUrl.each_index  do |i|
          method = resUrl[i]
          
          args[:params] = []
                    
          args[:i] = i
          args[:urlParams].shift
          
          nextResInfo = nil
          resInfo = self._resInfo(method,resObj)
          unless lastIndex == i
            nextMethod = resUrl[i+1]
            nextResInfo = self._resInfo(nextMethod,resObj)
            p nextResInfo.empty?,resInfo[:nargs], resInfo
            if nextResInfo.empty? and resInfo[:nargs] == 1
              p "bbbbb",nextMethod,nextMethod =~ /^\d+$/
              if nextMethod =~ /^\d+$/ and arguments[:convertNumbers]
                args[:params] = [ nextMethod.to_i ]
              else
                args[:params] = [ nextMethod ]
              end
              
            end
          end
          
          if i == lastIndex
            unless args[:reqParams].nil?
              
              if args[:reqParams].is_a?Array
                args[:params] = args[:reqParams]
              else
                args[:params] = [ args[:reqParams] ]
              end
            end 
          end
          
          resObj = self.execCode(resInfo,resObj,args)
         
          
#          if !@customHandler.nil? and @customHandler.respond_to?:call
#            methodHandled = true
#            resObj = @customHandler.call(@resources,args)
#          elsif !@customHandler.nil? and @customHandler.respond_to?method.to_sym
#            methodHandled = true
#            resObj = @customHandler.send(method.to_sym,@resources,args)
#          elsif !@customHandler.nil? and @customHandler.respond_to?nameHandler
#            methodHandled = true
#            resObj = @customHandler.send(nameHandler,@resources,args)
#          elsif !@customHandler.nil? and @customHandler.respond_to?:key
#            if @customHandler.key?method
#              custMeth = @customHandler[method]
#              if custMeth.respond_to?:call
#                methodHandled = true
#                resObj = custMeth.call(@resources,args)
#              end
#            elsif @customHandler.key?method.to_sym
#              custMeth = @customHandler[method.to_sym]
#              if custMeth.respond_to?:call
#                methodHandled = true
#                resObj = custMeth.call(@resources,args)
#              end
#            end 
#          elsif resObj.respond_to?:call
#            if params.is_a?Array
#              resObj = resObj.call(@resources,args)
#            else
#              resObj = resObj.call(@resources,args)
#            end
#          elsif resObj.respond_to?method.to_sym
#            if params.is_a?Array
#              resObj = resObj.send(method.to_sym,*params)
#            else
#              resObj = resObj.send(method.to_sym,params)
#            end
#          elsif resObj.respond_to?nameHandler
#            resObj = resObj.send(nameHandler,args)
#          else # no method on resource 
#            if resObj.respond_to?:key
#              
#              if resObj.key?method
#                obj = resObj[method]
#              elsif resObj.key?method.to_sym
#                obj = resObj[method.to_sym]
#              end
#              
#              if obj.respond_to?:call
#                if params.is_a?Array
#                  resObj = obj.call(*params)
#                else
#                  resObj = obj.call(params)
#                end
#              else
#                resObj = obj
#              end
#              
#            else # no key as method
#                            
#              methodHandled = false
#                       
#              unless methodHandled
#                
#                if resObj.respond_to?:method_missing
#                  resObj = resObj.send(method,args)
#                else 
#                  raise TargetResourcesException.new("Resource [#{method}] Not Found")
#                end
#              
#              end
#                  
#            end
#            
#          end
#          
#          return resObj if arguments[:endUrlParams]
#          
        end ## end loop on chunk url method
        
        resObj
      end
      
      def execCode(resInfo,resObj,args)
        p args 
        if resInfo[:type] == :method
          return resObj.send(resInfo[:name],*args[:params])
        end
        
      end
      
      def _resInfo(method,resObj)
        
        resInfo = {}
        nameHandler = "handler#{method.to_s.capitalize}".to_sym
        
        if !@customHandler.nil? and @customHandler.respond_to?:call
          resInfo = { name: nil, type: :customBlock, nargs: @customHandler.arity }
        elsif !@customHandler.nil? and @customHandler.respond_to?method.to_sym
          resInfo = { name: method.to_sym, type: :customMethod, nargs:  @customHandler.method(method.to_sym).arity}
        elsif !@customHandler.nil? and @customHandler.respond_to?nameHandler
          resInfo = { name: nameHandler, type: :customHandler, nargs:  @customHandler.method(nameHandler).arity}
        elsif !@customHandler.nil? and @customHandler.respond_to?:key
          if @customHandler.key?method
            custMeth = @customHandler[method]
            if custMeth.respond_to?:call
              resInfo = { name: nameHandler, type: :customHash, nargs: custMeth.arity }
            end
          elsif @customHandler.key?method.to_sym
            custMeth = @customHandler[method.to_sym]
            if custMeth.respond_to?:call
              resInfo = { name: nameHandler, type: :customHash, nargs: custMeth.arity }
            end
          end 
        elsif resObj.respond_to?:call
          resInfo = { name: nil, type: :block, nargs: resObj.arity }
        elsif resObj.respond_to?method.to_sym
          resInfo = { name: method.to_sym, type: :method, nargs: resObj.method(method.to_sym).arity}
        elsif resObj.respond_to?nameHandler
          resInfo = { name: nameHandler, type: :handler, nargs: resObj.method(nameHandler).arity}
        elsif resObj.respond_to?:key
          if resObj.key?method
            custMeth = resObj[method]
            if custMeth.respond_to?:call
              resInfo = { name: nameHandler, type: :hash, nargs: custMeth.arity }
            end
          elsif resObj.key?method.to_sym
            custMeth = resObj[method.to_sym]
            if custMeth.respond_to?:call
              resInfo = { name: nameHandler, type: :hash, nargs: custMeth.arity }
            end
          end         
        end
      
        resInfo 
      end
     
    end
  
    class TargetResourcesException < StandardError
      def initialize(msg="Exception on target resouces")
        super
      end
    end
  
  end
  
end
