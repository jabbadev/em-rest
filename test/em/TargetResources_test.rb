require 'test_helper'

describe EM::Rest::TargetResources do
  
  before do
  end
  
  describe "Expose an object as web resource" do
    it "GET request" do
      resource = EM::Rest::TargetResources.new(EmpireDB.new)
      resource.exec("GET","/empire")[0][:name].must_equal("Darth Sidious")
      resource.exec("GET","/get/all")
      p resource.exec("GET","/get/3")
      resource.exec("GET","/get/sith/3")
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
