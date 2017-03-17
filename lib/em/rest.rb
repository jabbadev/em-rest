require 'eventmachine'
require "em/rest/version"
require "json"

module EventMachine
  module Rest
     
    class Connection < EventMachine::Connection
      def initialize(resources,options={})
        @target = TargetResources.new(resources,options)
      end
      
      def post_init()
        @data = ""
        @body = ""
        @sectionHeader = false 
      end
      
      def receive_data(data)
        @data += data
        if @data =~ /\r\n\r\n/ and !@sectionHeader
          @sectionHeader = true
          (h,b) = @data.split("\r\n\r\n")
          headers = h.split("\r\n")
          reqLine = headers.shift
          ( @method, @uri, @httpVer ) = reqLine.split(" ")
          
          @urlReqParams = (@uri =~ /\?(.+$)/) && /\?(.+$)/.match(@uri)[1].split("&") || nil
          
          @headers = headers.map{|h| /(^[^()<>@\,;:"\/\[\]?={}]+):\s+(.+$)/.match(h)[1,2] }.to_h
          
          if @headers.key?'Content-Length' and @headers['Content-Length'].to_i > 0
            @cl = @headers['Content-Length'].to_i
            @data = @body = b
            if @body.size == @cl
              self.gestRequest()
            end
          else
            self.gestRequest()
          end
        else
          @body += data
          if @body.size == @cl
            self.gestRequest()
          end
        end
      end    
      
      def gestRequest
        begin 
          if @method == "GET"
            data = @target.exec(httpVerb: "GET", httpUrl: @uri ,reqParams: @urlReqParams )
          elsif @method == "POST"
            if @headers["Content-Type"] == "application/json"
              reqParams = (!@body.nil?) && JSON.parse(@body)||nil
            else
              reqParams = @body
            end
            
            data = @target.exec(httpVerb: "POST", httpUrl: @uri ,reqParams: reqParams)
          end
         
          unless data.nil?
            chunk = data.to_json       
            send_data("#{@httpVer} 200 OK\r\n")           
            send_data("Content-Type: application/json;charset=UTF-8\r\n")
            send_data("transfer-encoding: chunked\r\n")
            send_data("\r\n")
            send_data("#{chunk.size.to_s(16)}\r\n") ### Exadecimal size chunk ###
            send_data("#{chunk}\r\n")
            send_data("0\r\n")
            send_data("\r\n")
          end
        
        rescue 
          send_data("#{@httpVer} 500 Internal Server Error\r\n")
          send_data("Content-Length: 0\r\n")
          send_data("Connection: close\r\n")
          send_data("\r\n")
        end
        
      end
      
    end
    
    class TargetResources
      
      def initialize(resources,options={})
        options = {
          url_mapper: [],
          custom_handler: nil
        }.merge(options)
        
        @resources = resources
        @customHandler = options[:custom_handler]
        @urlMapper = options[:url_mapper].collect{|url| { mapper: url, regexp: Regexp.new(url) }}
        
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
        
        matchValues = nil
        unless @urlMapper.empty?
          @urlMapper.each do |mapper|
            m = mapper[:regexp].match(httpUrl)
            if m
              matchValues = m.to_a
              matchValues.shift
              resUrl = mapper[:mapper].split('/')
              resUrl.shift  
            end 
          end
        end
         
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
          #p resInfo
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
              if resInfo[:nargs] == 0
                ### call method without params
                args[:params] = []
              elsif resInfo[:nargs] == -1
                ### Check if next resUrl is a param mapper value ###
                if resUrl[i+1] =~ /^\(.+\)$/
                  resUrl[i+1] = matchValues.shift
                  args[:params] = self._nextUrlParam(resUrl[i+1],arguments)
                  i += 1
                end
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
            #p "fire exec resinfo: #{resInfo}, #{resObj}, #{args}"
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
