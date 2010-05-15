require 'rubygems'
require 'test/unit'
require 'contest'
require 'sinatra/base'
require 'rack/test'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rack/mail_exception'

class Test::Unit::TestCase
end
