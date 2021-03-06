require 'test_helper'

class ConfigurationTest < Test::Unit::TestCase
  should "provide default values" do
    assert_config_default :proxy_host,          nil
    assert_config_default :proxy_port,          nil
    assert_config_default :proxy_user,          nil
    assert_config_default :proxy_pass,          nil
    assert_config_default :project_root,        nil
    assert_config_default :environment_name,    nil
    assert_config_default :logger,              nil
    assert_config_default :notifier_version,    Honeybadger::VERSION
    assert_config_default :notifier_name,       'Honeybadger Notifier'
    assert_config_default :notifier_url,        'https://github.com/honeybadger-io/honeybadger-ruby'
    assert_config_default :secure,              true
    assert_config_default :host,                'api.honeybadger.io'
    assert_config_default :http_open_timeout,   2
    assert_config_default :http_read_timeout,   5
    assert_config_default :ignore_by_filters,   []
    assert_config_default :ignore_user_agent,   []
    assert_config_default :params_filters,
                          Honeybadger::Configuration::DEFAULT_PARAMS_FILTERS
    assert_config_default :backtrace_filters,
                          Honeybadger::Configuration::DEFAULT_BACKTRACE_FILTERS
    assert_config_default :ignore,
                          Honeybadger::Configuration::IGNORE_DEFAULT
    assert_config_default :framework, 'Standalone'
    assert_config_default :source_extract_radius, 2
    assert_config_default :async, nil
    assert_config_default :send_request_session, true
    assert_config_default :debug, false
  end

  should "configure async as Proc" do
    config = Honeybadger::Configuration.new
    async_handler = Proc.new { |n| n.deliver }
    assert !config.async?, 'Configuration#async? should be falsey'
    config.async = async_handler
    assert config.async?, 'Configuration#async? should be truthy'
    assert_equal config.async, async_handler
  end

  should "configure async with block" do
    config = Honeybadger::Configuration.new
    assert !config.async?, 'Configuration#async? should be falsey'
    config.async { |n| n }
    assert config.async?, 'Configuration#async? should be truthy'
    assert_equal config.async.call('foo'), 'foo'
  end

  should "stub current_user_method" do
    config = Honeybadger::Configuration.new
    assert_nothing_raised { config.current_user_method = :foo }
  end

  should "provide default values for secure connections" do
    config = Honeybadger::Configuration.new
    config.secure = true
    assert_equal 443, config.port
    assert_equal 'https', config.protocol
  end

  should "provide default values for insecure connections" do
    config = Honeybadger::Configuration.new
    config.secure = false
    assert_equal 80, config.port
    assert_equal 'http', config.protocol
  end

  should "not cache inferred ports" do
    config = Honeybadger::Configuration.new
    config.secure = false
    config.port
    config.secure = true
    assert_equal 443, config.port
  end

  should "allow values to be overwritten" do
    assert_config_overridable :proxy_host
    assert_config_overridable :proxy_port
    assert_config_overridable :proxy_user
    assert_config_overridable :proxy_pass
    assert_config_overridable :secure
    assert_config_overridable :host
    assert_config_overridable :port
    assert_config_overridable :http_open_timeout
    assert_config_overridable :http_read_timeout
    assert_config_overridable :project_root
    assert_config_overridable :notifier_version
    assert_config_overridable :notifier_name
    assert_config_overridable :notifier_url
    assert_config_overridable :environment_name
    assert_config_overridable :logger
    assert_config_overridable :source_extract_radius
    assert_config_overridable :async
    assert_config_overridable :send_request_session
    assert_config_overridable :debug
  end

  should "have an api key" do
    assert_config_overridable :api_key
  end

  should "act like a hash" do
    config = Honeybadger::Configuration.new
    hash = config.to_hash
    [:api_key, :backtrace_filters, :development_environments,
     :environment_name, :host, :http_open_timeout, :http_read_timeout, :ignore,
     :ignore_by_filters, :ignore_user_agent, :notifier_name, :notifier_url,
     :notifier_version, :params_filters, :project_root, :port, :protocol,
     :proxy_host, :proxy_pass, :proxy_port, :proxy_user, :secure,
     :source_extract_radius, :async, :send_request_session, :debug].each do |option|
      assert_equal config[option], hash[option], "Wrong value for #{option}"
    end
  end

  should "be mergable" do
    config = Honeybadger::Configuration.new
    hash = config.to_hash
    assert_equal hash.merge(:key => 'value'), config.merge(:key => 'value')
  end

  should "allow param filters to be appended" do
    assert_appends_value :params_filters
  end

  should "allow ignored user agents to be appended" do
    assert_appends_value :ignore_user_agent
  end

  should "allow backtrace filters to be appended" do
    assert_appends_value(:backtrace_filters) do |config|
      new_filter = lambda {}
      config.filter_backtrace(&new_filter)
      new_filter
    end
  end

  should "allow ignore by filters to be appended" do
    assert_appends_value(:ignore_by_filters) do |config|
      new_filter = lambda {}
      config.ignore_by_filter(&new_filter)
      new_filter
    end
  end

  should "allow ignored exceptions to be appended" do
    config = Honeybadger::Configuration.new
    original_filters = config.ignore.dup
    new_filter = 'hello'
    config.ignore << new_filter
    assert_same_elements original_filters + [new_filter], config.ignore
  end

  should "allow ignored exceptions to be replaced" do
    assert_replaces(:ignore, :ignore_only=)
  end

  should "allow ignored user agents to be replaced" do
    assert_replaces(:ignore_user_agent, :ignore_user_agent_only=)
  end

  should "use development and test as development environments by default" do
    config = Honeybadger::Configuration.new
    assert_same_elements %w(development test cucumber), config.development_environments
  end

  should "be public in a public environment" do
    config = Honeybadger::Configuration.new
    config.development_environments = %w(development)
    config.environment_name = 'production'
    assert config.public?
  end

  should "not be public in a development environment" do
    config = Honeybadger::Configuration.new
    config.development_environments = %w(staging)
    config.environment_name = 'staging'
    assert !config.public?
  end

  should "be public without an environment name" do
    config = Honeybadger::Configuration.new
    assert config.public?
  end

  should "use the assigned logger if set" do
    config = Honeybadger::Configuration.new
    config.logger = "CUSTOM LOGGER"
    assert_equal "CUSTOM LOGGER", config.logger
  end

  should 'give a new instance if non defined' do
    Honeybadger.configuration = nil
    assert_kind_of Honeybadger::Configuration, Honeybadger.configuration
  end

  def assert_config_default(option, default_value, config = nil)
    config ||= Honeybadger::Configuration.new
    assert_equal default_value, config.send(option)
  end

  def assert_config_overridable(option, value = 'a value')
    config = Honeybadger::Configuration.new
    config.send(:"#{option}=", value)
    assert_equal value, config.send(option)
  end

  def assert_appends_value(option, &block)
    config = Honeybadger::Configuration.new
    original_values = config.send(option).dup
    block ||= lambda do |config|
      new_value = 'hello'
      config.send(option) << new_value
      new_value
    end
    new_value = block.call(config)
    assert_same_elements original_values + [new_value], config.send(option)
  end

  def assert_replaces(option, setter)
    config = Honeybadger::Configuration.new
    new_value = 'hello'
    config.send(setter, [new_value])
    assert_equal [new_value], config.send(option)
    config.send(setter, new_value)
    assert_equal [new_value], config.send(option)
  end
end
