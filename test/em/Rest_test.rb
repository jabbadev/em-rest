require 'test_helper'
require 'em/minitest/spec'
require 'em-http-request'
require 'json'

describe EM::Rest do
  
  describe "Rest server" do
    include EM::MiniTest::Spec
    
    def timeout_interval
      5
    end
    
    it "REST GET REQUEST" do
      if EM.reactor_running?
        
        server = EM.start_server "127.0.0.1",1991, EventMachine::Rest::Connection,EmpireDB.new, nil
                  
        empireGET = EventMachine::HttpRequest.new('http://127.0.0.1:1991/empire').get
        empireGET.callback {|r|
          JSON.parse(r.response)[0]['name'].must_equal("Darth Sidious")
          done!
        }
                            
      end
          
      wait!
                 
    end
    
    it "REST POST REQUEST" do
      if EM.reactor_running?
        server = EM.start_server "127.0.0.1",1991, EventMachine::Rest::Connection,EmpireDB.new, nil
             
        empirePOST = EventMachine::HttpRequest.new('http://127.0.0.1:1991/addToEmpire').
          post :head => {"Content-Type" => "application/json"}, :body => { name: "Kanan Jarrus", rank: "Padawan",type: "jedi" }.to_json
        empirePOST.callback {|r|
          JSON.parse(r.response)['id'].must_equal(6)
          
          empireGET = EventMachine::HttpRequest.new('http://127.0.0.1:1991/empire/size').get
          empireGET.callback {|r|
            r.response.to_i.must_equal(7)
            done!
          }
          
        }
        
      end
        
      wait!
               
    end
     
  end
   
end
