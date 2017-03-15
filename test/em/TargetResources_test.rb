require 'test_helper'

describe EM::Rest::TargetResources do
  
  before do
  end
  
  describe "Expose an object as web resource" do
    it "GET request" do
      
      srtResorce = EM::Rest::TargetResources.new("star wars empire")
      srtResorce.exec(httpVerb: "GET", httpUrl: "/slice",reqParams: [5,4] ).must_equal("wars")
      srtResorce.exec(httpVerb: "GET", httpUrl: "/slice",reqParams: 5 ).must_equal("w")
      srtResorce.exec(httpVerb: "GET", httpUrl: "/upcase/slice", reqParams: [5,4] ).must_equal("WARS")
      srtResorce.exec(httpVerb: "GET", httpUrl: "/concat/", reqParams: " droids" ).must_equal("star wars empire droids")
      
      resource = EM::Rest::TargetResources.new(EmpireDB.new)
      resource.exec(httpVerb: "GET", httpUrl: "/empire")[0][:name].must_equal("Darth Sidious")
      resource.exec(httpVerb: "GET", httpUrl: "/empire/at/3")[:name].must_equal("Luke Skywalker")
      resource.exec(httpVerb: "GET", httpUrl: "/get/3")[:name].must_equal("Luke Skywalker")
          
      lambda {
        resource.exec(httpVerb: "GET", httpUrl: "/empireWithReqParams", reqParams: [:name,:type])[2].must_equal({name: "Darth Vader", type: "sith"})
      }.must_raise(ArgumentError)
      resource.exec(httpVerb: "GET", httpUrl: "/empireWithReqParams", reqParams: [:name,:type], arrayAsMethodArguments: false)[2].must_equal({name: "Darth Vader", type: "sith"})
        
      resource.exec(httpVerb: "GET", httpUrl: "/getWithReqParams/3",reqParams: [:name,:type]).must_equal({name: "Luke Skywalker", type: "jedi"})
      
      resource.exec(httpVerb: "GET", httpUrl: "/getByType/sith/at/2")[:name].must_equal("Darth Vader")
      resource.exec(httpVerb: "GET", httpUrl: "/find_by_name/Yo")[0][:rank].must_equal("Big Master")
      resource.exec(httpVerb: "GET", httpUrl: "/find_by_name/Dart").size.must_equal(3)
     
      ### Custom Handler ###
      
      resCustomCodeHandler = EM::Rest::TargetResources.new(EmpireDB.new,
        custom_handler: 
          lambda{|empireDB,method,urlParam|
            if method == :find_by_rank 
              empireDB.empire.select{|r| r[:rank] == urlParam }
            else
              raise EM::Rest::TargetResourcesException.new("resource [#{method}] not found")
            end
      })
        
      resCustomCodeHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Master").size.must_equal(3)
      
      resObjectHandler = EM::Rest::TargetResources.new(EmpireDB.new, custom_handler: ObjectHandler.new)
      resObjectHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Master").size.must_equal(3)
      
      resModuleHandler = EM::Rest::TargetResources.new(EmpireDB.new,custom_handler: ModuleHandler)
      resModuleHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Big Master").size.must_equal(1)
      
      resHashHandler = EM::Rest::TargetResources.new(EmpireDB.new,custom_handler: {
        find_by_rank: lambda{|empireDB,args| empireDB.empire.select{|r|r[:rank] == args}}
      })
      resHashHandler.exec(httpVerb: "GET", httpUrl: "/find_by_rank/Big Master").size.must_equal(1)
      
      resGestNoEndParamUrl = EM::Rest::TargetResources.new(EmpireDB.new,custom_handler: GestNoEndParamUrl.new)
      #resGestNoEndParamUrl.exec(httpVerb: "GET", httpUrl: "/_empire/sith/1/name", endUrlParams: false).must_equal("Darth Maul")
      #resGestNoEndParamUrl.exec(httpVerb: "GET", httpUrl: "/_empire/sith/2/rank/upcase", endUrlParams: false).must_equal("APPRENTICE")
      
      ### Mapper ###
      
      resourceWithMapper = EM::Rest::TargetResources.new(EmpireDB.new,
        url_mapper: ["/sith/(\\d+)"] )
      resourceWithMapper.exec(httpVerb: "GET", httpUrl: "/sith")[1][:name].must_equal("Darth Maul")
      resourceWithMapper.exec(httpVerb: "GET", httpUrl: "/sith/1")[:name].must_equal("Darth Maul")
      
    end
    
    it "POST request" do
      resource = EM::Rest::TargetResources.new(EmpireDB.new)
      resource.exec(httpVerb: "POST", httpUrl: "/addToEmpire", reqParams: { name: "Kanan Jarrus", rank: "Padawan",type: "jedi" })
      resource.exec(httpVerb: "GET", httpUrl: "/empire/size").must_equal(7)
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
