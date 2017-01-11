$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'em/rest'
require 'minitest/autorun'

class EmpireDB
  
  def initialize()
    @data = [
      ['Darth Sidious','master','sith'],
      ['Darth Maul','mpprentice','sith'],
      ['Darth Vader','mpprentice','sith'],
      ['Luke Skywalker','master','jedi'],
      ['Obi-Wan Kenobi','master','jedi'],
      ['Yoda','Big master','jedi']
    ].collect{|r| { name: r[0], rank: r[1],type: r[2] } }
  end
  
  def empire()
    @data
  end
  
  def method_missing(method,*args)
    p method,args
    if(method=="get")
      p args[:params][0]
      if args[:params][0].is_a? Numeric
        self.getByIndex(args[:params][0])
      else
        
      end
    end
  end
  
  def getByIndex(i)
    return @data[i]
  end
end

