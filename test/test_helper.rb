$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'em/rest'
require 'minitest/autorun'

class EmpireDB
  
  def initialize()
    @data = [
      ['Darth Sidious','Master','sith'],
      ['Darth Maul','Apprentice','sith'],
      ['Darth Vader','Apprentice','sith'],
      ['Luke Skywalker','Master','jedi'],
      ['Obi-Wan Kenobi','Master','jedi'],
      ['Yoda','Big Master','jedi']
    ].collect{|r| { name: r[0], rank: r[1],type: r[2] } }
  end
  
  def empire()
    @data
  end
  
  def method_missing(method,args)
    if(method==:get)
      if args[:urlParams][0] =~ /^\d+$/
        return self.getByIndex(args[:urlParams][0].to_i)
      else
        if args[:urlParams][0] == "all"
          return self.getAllEmpire(args[:urlParams][0])
        else
          return self.getByType(args[:urlParams][0],args[:urlParams][1].to_i) 
        end
      end
    end
  end
  
  def getByIndex(i)
    @data[i]
  end

  def getByType(type,i)
    @data.select{|r|type == r[:type]}[i]
  end 
  
  def getAllEmpire(i)
    self.empire()
  end
  
  def handlerFind_by_name(args)
    name = args[:urlParams][0]
    @data.select{|r| r[:name].include?name}
  end
  
#  def addToEmpire(args) 
#    p args
#  end
  
end

class ObjectHandler
  def find_by_rank(resources,args)
    resources.empire.select{|r|r[:rank] == args[:urlParams][0]}
  end
end

module ModuleHandler
  def self.find_by_rank(resources,args)
    resources.empire.select{|r|r[:rank] == args[:urlParams][0]}
  end
end

class GestNoEndParamUrl
   
  def _empire(empire,args) 
    type = args[:urlParams][0]
    lambda {|empire,args|
      ## Gest index ## 
      index = args[:urlParams][0].to_i
      lambda {|empire,args|
        ## Gest prop ##
        prop = args[:urlParams][0]
        lambda {|empire,args|
          self.doEmpireRequest(empire,type,index,prop)
        }
      }
    }
  end
  
  def doEmpireRequest(empire,type,index,prop)
    empire.empire.select{|r|type == r[:type]}[index][prop.to_sym]
  end
end