require 'test_helper'
require 'em/minitest/spec'
require 'em-http-request'

describe EM::Rest do
  include EM::MiniTest::Spec
  
  describe "Rest server" do
    
    it "REST GET REQUEST" do
        wait_for do
          p "wait for"
          if EM.reactor_running?
            
           EM.start_server "10.55.68.138", 1991 , EventMachine::Rest::Connection, "pippo", nil
           
           empireGET = EventMachine::HttpRequest.new('http://10.55.68.138:1991/empire').get
           empireGET.callback {|response|
                puts response[:status]
                puts response[:headers]
                puts response[:content]
                  assert true
           }
            
          end
         
        end   
                 
    end
     
    it "REST POST REQUEST" do
           
    end     
    
  end
   
end
