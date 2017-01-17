require 'test_helper'

describe EM::Rest::TargetResources do
  
  before do
  end
  
  describe "Expose an object as web resource" do
    it "GET request" do
      resource = EM::Rest::TargetResources.new(EmpireDB.new)
      resource.exec("GET","/empire")[0][:name].must_equal("Darth Sidious")
      resource.exec("GET","/get/all").size.must_equal(6)
      resource.exec("GET","/get/3")[:name].must_equal("Luke Skywalker")
      resource.exec("GET","/get/sith/2")[:name].must_equal("Darth Vader")
      resource.exec("GET","/find_by_name/Yo")[0][:rank].must_equal("Big Master")
      resource.exec("GET","/find_by_name/Dart").size.must_equal(3)
      
      resCodeHandler = EM::Rest::TargetResources.new(EmpireDB.new,lambda{|resources,args| resources.empire.select{|r| r[:rank] == args[:urlParams][0]} })
      resCodeHandler.exec("GET","/find_by_rank/Master").size.must_equal(3)
      
      resObjectHandler = EM::Rest::TargetResources.new(EmpireDB.new,ObjectHandler.new)
      resObjectHandler.exec("GET","/find_by_rank/Master").size.must_equal(3)
      
      resModuleHandler = EM::Rest::TargetResources.new(EmpireDB.new,ModuleHandler)
      resModuleHandler.exec("GET","/find_by_rank/Big Master").size.must_equal(1)
      
      resHashHandler = EM::Rest::TargetResources.new(EmpireDB.new,{
        find_by_rank: lambda{|resources,args| resources.empire.select{|r|r[:rank] == args[:urlParams][0]}}
      })
      resHashHandler.exec("GET","/find_by_rank/Big Master").size.must_equal(1)
      
    end
  end
  
  describe "Expose a Ruby Module as web resource" do
    it ""
  end
  
#  describe "when asked about cheeseburgers" do
#    it "must respond positively" do
#      @meme.i_can_has_cheezburger?.must_equal "OHAI!"
#    end
#  end
#
#  describe "when asked about blending possibilities" do
#    it "won't say no" do
#      @meme.will_it_blend?.wont_match /^no/i
#    end
#  end
  
end
