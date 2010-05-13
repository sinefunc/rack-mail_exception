require 'helper'

class TestBullhorn < Test::Unit::TestCase
  class HelloWorld < Sinatra::Base
    use Bullhorn, :to => "me@me.com", :from => "you@you.com",
      :subject => "[FooBar Exception] %s"
  
    enable :raise_errors

    get '/success' do
      "Successful"
    end

    get '/failure' do
      raise "Failed"
      "Failure"
    end
  end

  def app
    HelloWorld.new
  end
  
  context "when going to /success" do
    include Rack::Test::Methods

    should "render properly" do
      get "/success"
      
      assert_equal 'Successful', last_response.body
    end
  end

  context "when going to /failure" do
    include Rack::Test::Methods

    should "send an email" do
      Mail.expects(:deliver).with() { |h|
        h[:to] == "me@me.com" && 
          h[:from] == "you@you.com" &&
            h[:subject] == "[FooBar Exception] Failed" &&
              h[:body] =~ /A RuntimeError occured: Failed/
      }
      
      get "/failure"
    end

    should "still respond with the original body" do
      Mail.expects(:deliver)

      get "/failure"
      
      title = /<title>RuntimeError at \/failure<\/title>/
      assert_match(title, last_response.body)
    end
  end
end
