require 'eventmachine'
require "em/rest/version"

module EventMachine
  module Rest
     
    class Connection < EventMachine::Connection
      def initialize(resources,customHandler=nil)
         p "initialize ...."
         #@target = EM::Rest::TargetResources.new(resources,customHandler)
        @target = TargetResources.new(resources,customHandler)
      end
      
      def post_init()
        p "post init"
        @data = ""
        @body = ""
        @isHeaderParsed = false 
      end
      
      def receive_data(data)
        @data += data
        p @data
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
        arguments = {
          convertNumbers: true,
          arrayAsMethodArguments: true 
        }.merge(arguments)
        
        resUrl = httpUrl.split('/')
        resUrl.shift
        
        args = { httpVerb: httpVerb,
                 httpUrl: httpUrl,
                 reqParams: reqParams,
                 resUrl: resUrl,
                 urlParams: resUrl.clone() }
        
        resObj = @resources
        
        lastIndex = resUrl.size - 1
        #resUrl.each_index  do |i|
        i = -1
        while i < lastIndex
          i += 1 
          method = resUrl[i]
          
          args[:params] = []
                    
          args[:i] = i
          args[:urlParams].shift
          
          nextResInfo = nil
          resInfo = self._resInfo(method,resObj)
          p resInfo
          unless lastIndex == i
            
            if resInfo[:type] == :customBlock
              resInfo[:name] = method.to_sym
              if resInfo[:nargs] == 3 #### block with no arguments ####
                args[:params] = self._nextUrlParam(resUrl[i+1],arguments)
                i += 1  
              end
            elsif resInfo[:type] == :customMethod
              if resInfo[:nargs] == 2
                args[:params] = self._nextUrlParam(resUrl[i+1],arguments)
                i += 1
              end
            elsif resInfo[:type] == :customHash
              if resInfo[:nargs] == 2 #### block with no arguments ####
                args[:params] = self._nextUrlParam(resUrl[i+1],arguments)
                i += 1  
              end
            elsif resInfo[:type] == :method
              if ( resInfo[:nargs] == 0 or resInfo[:nargs] == -1 )
                ### call method without params
                args[:params] = []
              elsif resInfo[:nargs] >= 1 or resInfo[:nargs] <= -2
                ### method(url_param,<req_param>)or method(<url_param>,*req_params) ###
                args[:params] = self._nextUrlParam(resUrl[i+1],arguments)
                i += 1
                if i == lastIndex
                  args = self._addRequestParams(args,arguments)
                  #args[:params].push(args[:reqParams]) unless args[:reqParams].nil?
                end
              end
            else
              
              raise ResourceNotFound, "Resource not found [#{method}]"  
            end
          else
            args = self._addRequestParams(args,arguments)
          end
          
          begin
            resObj = self.execCode(resInfo,resObj,args)
          rescue ArgumentError => e
            raise ArgumentError.new("#{e.message} calling: #{resInfo} with params: [#{args[:params]}]")  
          end
                   
        end ## end loop on chunk url method
        
        resObj
      end
      
      def _addRequestParams(args,arguments)
        unless args[:reqParams].nil?
          if args[:reqParams].is_a?Array and
            if arguments[:arrayAsMethodArguments]
              args[:params].concat(args[:reqParams])
            else
              args[:params].push(args[:reqParams])
            end
          else
            args[:params].push(args[:reqParams])
          end
        end
        args
      end
      
      def _nextUrlParam(nextMethod,arguments)
        ( nextMethod =~ /^\d+$/ and arguments[:convertNumbers] ) ? [ nextMethod.to_i ] : [ nextMethod ]
      end
      
      def execCode(resInfo,resObj,args)
        if resInfo[:type] == :customBlock
          args[:params].insert(0,resInfo[:name])
          return @customHandler.call(resObj,*args[:params])
        elsif resInfo[:type] == :customHash
          return @customHandler[resInfo[:name]].call(resObj,*args[:params])
        elsif resInfo[:type] == :customMethod
          args[:params].insert(0,resObj)
          return @customHandler.send(resInfo[:name],*args[:params])
        elsif resInfo[:type] == :method
          p args[:params]
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
              resInfo = { name: method, type: :customHash, nargs: custMeth.arity }
            end
          elsif @customHandler.key?method.to_sym
            custMeth = @customHandler[method.to_sym]
            if custMeth.respond_to?:call
              resInfo = { name: method.to_sym, type: :customHash, nargs: custMeth.arity }
            end
          end 
        elsif resObj.respond_to?:call
          resInfo = { name: nil, type: :block, nargs: resObj.arity }
        elsif resObj.respond_to?method.to_sym
          resInfo = { name: method.to_sym, type: :method, nargs: resObj.method(method.to_sym).arity}
        elsif resObj.respond_to?nameHandler
          resInfo = { name: nameHandler, type: :method, nargs: resObj.method(nameHandler).arity}
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
 
    class ResourceNotFound < StandardError
      def initialize(msg="Resource Not Found")
        super(msg)
      end
    end
    
    class TargetResourcesException < StandardError
      def initialize(msg="Exception on target resouces")
        super
      end
    end
  
  end
  
end
