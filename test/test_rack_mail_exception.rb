require 'helper'

class TestRackMailException < Test::Unit::TestCase
  class HelloWorld < Sinatra::Base
    use Rack::MailException, :to => "me@me.com", :from => "you@you.com",
      :subject => "[FooBar Exception] %s"

    enable :raise_errors

    get '/success' do
      "Successful"
    end

    get '/failure' do
      raise "Failed"
      "Failure"
    end

    post '/login' do
      raise 'Login Failed'
    end
  end

  class FilteredPassword < Sinatra::Base
    use Rack::MailException, :to => "me@me.com", :from => "you@you.com",
      :subject    => "[FooBar Exception] %s",
      :filters    => %w(password password_confirmation)

    post '/login' do
      raise "Login Failure"
    end
  end

  def app
    HelloWorld.new
  end

  include Rack::Test::Methods

  context "when going to /success" do
    should "render properly" do
      get "/success"

      assert_equal 'Successful', last_response.body
    end
  end

  context "when going to /failure" do
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

  context "when posting to /login" do
    should "by default display the results unfiltered" do
      post '/login', :username => "quentin", :password => "test"

      assert(last_response.body =~ /password=test/)
    end
  end

  context "when posting to /login in filtered context" do
    def app
      FilteredPassword.new
    end

    should "filter out password" do
      Mail.expects(:deliver).with() { |hash|
        hash[:body] !~ /password=mypass/ &&
          hash[:body] !~ /"password"=>"mypass"/ &&
            hash[:body] !~ /'password'=>'mypass'/
      }

      post "/login", :password => "mypass"
    end
  end
end