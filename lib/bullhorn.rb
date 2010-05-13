require 'mime/types'
require 'erb'

if RUBY_VERSION >= "1.9.1"
  # The bundled mail library doesn't include activesupport.
  # Caveat is, it needs Ruby 1.9.x at least for the multibyte character 
  # support. Why bother? Because ActiveSupport is evil, and we don't use
  # Rails. The memory overhead is just not worth it.
  $:.unshift(File.join(File.dirname(__FILE__), '..', 'vendor', 'mail', 'lib'))
end

require 'mail'

class Bullhorn
  VERSION = "0.0.1"

  def initialize(app, options = {})
    @to      = options[:to]      || raise(ArgumentError, ":to is required")
    @from    = options[:from]    || raise(ArgumentError, ":from is required")
    @subject = options[:subject] || "[Application Exception] %s"
    @app     = app
  end

  def call(env)
    status, headers, body =
      begin
        @app.call(env)
      rescue Exception => ex
        notify ex, env
        raise ex
      end

    [status, headers, body]
  end

private
  def notify(exception, env)
    text = ERB.new(TEMPLATE).result(binding)

    Mail.deliver(
      :to      => @to,
      :from    => @from,
      :subject => @subject % exception,
      :body    => text
    )
  end

  def request_body(env)
    if io = env['rack.input']
      io.rewind if io.respond_to?(:rewind)
      io.read
    end
  end

  # Taken from rack/contrib/mailexceptions
  TEMPLATE = (<<-'EMAIL').gsub(/^ {2}/, '')
  A <%= exception.class.to_s %> occured: <%= exception.to_s %>
  <% if body = request_body(env) %>

  ===================================================================
  Request Body:
  ===================================================================

  <%= body.gsub(/^/, '  ') %>
  <% end %>

  ===================================================================
  Rack Environment:
  ===================================================================

    PID:                     <%= $$ %>
    PWD:                     <%= Dir.getwd %>

    <%= env.to_a.
      sort{|a,b| a.first <=> b.first}.
      map{ |k,v| "%-25s%p" % [k+':', v] }.
      join("\n  ") %>

  <% if exception.respond_to?(:backtrace) %>
  ===================================================================
  Backtrace:
  ===================================================================

    <%= exception.backtrace.join("\n  ") %>
  <% end %>
  EMAIL
end
