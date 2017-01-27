require 'test_helper'

describe EM::Rest::TargetResources do
  
  before do
  end
  
  describe "Expose an object as web resource" do
    it "GET request" do
      resource = EM::Rest::TargetResources.new(EmpireDB.new)
      resource.exec(httpVerb: "GET", httpUrl: "/empire")[0][:name].must_equal("Darth Sidious")
      resource.exec(httpVerb: "GET", httpUrl: "/get/all").size.must_equal(6)
      resource.exec(httpVerb: "GET", httpUrl: "/get/3")[:name].must_equal("Luke Skywalker")
      resource.exec(httpVerb: "GET", httpUrl: "/get/sith/2")[:name].must_equal("Darth Vader")
      resource.exec(httpVerb: "GET", httpUrl: "/find_by_name/Yo")[0][:rank].must_equal("Big Master")
      resource.exec(httpVerb: "GET", httpUrl: "/find_by_name/Dart").size.must_equal(3)
      
      resCodeHandler = EM::Rest::TargetResources.new(EmpireDB.new,lambda{|resources,args| resources.empire.select{|r| r[:rank] == args[:urlParams][0]} })
      resCodeHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Master").size.must_equal(3)
      
      resObjectHandler = EM::Rest::TargetResources.new(EmpireDB.new,ObjectHandler.new)
      resObjectHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Master").size.must_equal(3)
      
      resModuleHandler = EM::Rest::TargetResources.new(EmpireDB.new,ModuleHandler)
      resModuleHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Big Master").size.must_equal(1)
      
      resHashHandler = EM::Rest::TargetResources.new(EmpireDB.new,{
        find_by_rank: lambda{|resources,args| resources.empire.select{|r|r[:rank] == args[:urlParams][0]}}
      })
      resHashHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Big Master").size.must_equal(1)
      
      lambda {
         resource.exec(httpVerb: "GET", httpUrl: "/get/sith/2", endUrlParams: false)
      }.must_raise(EM::Rest::TargetResourcesException)
      
      resGestNoEndParamUrl = EM::Rest::TargetResources.new(EmpireDB.new,GestNoEndParamUrl.new)
      resGestNoEndParamUrl.exec(httpVerb: "GET", httpUrl: "/_empire/sith/1/name", endUrlParams: false).must_equal("Darth Maul")
      resGestNoEndParamUrl.exec(httpVerb: "GET", httpUrl: "/_empire/sith/2/rank/upcase", endUrlParams: false).must_equal("APPRENTICE")
      
    end
    
#    it "POST request" do
#      resource = EM::Rest::TargetResources.new(EmpireDB.new)
#      resource.exec(httpVerb: "POST", httpUrl: "/addToEmpire", bodyReq: { name: "Kanan Jarrus", rank: "Padawan",type: "jedi" })[:id].must_equal(6)
#      p resource.exec(httpVerb: "GET", httpUrl: "/empire/size").must_equal(7)
#      
#      
#    end
    
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
