class Puppet::Resource::Catalog::CompilerCmGuard < Puppet::Indirector::Code

  def initialize
    super
    # we likely need that.
    Puppet::Util::Autoload.new(self,'puppet/cm_guard').load('mem_cache')
  end

  def find(request)
    if (catalog = cm_cache.find(request)).nil? || recompile?(request)
      return nil unless catalog = compiler.find(request)

      request.instance = catalog
      cm_cache.save(request)
    else
      Puppet.notice "Using cached catalog for #{request.key}"
    end
    catalog
  end

  protected

  def recompile?(request)
    basic_compiler.extract_facts_from_request(request)
    node = basic_compiler.send(:node_from_request,request)
    invalidator.recompile?(node)
  end

  def config
    @config ||= begin
      config_file = File.join(Puppet[:confdir],'cm_guard.yaml')
      fc = {}
      fc = YAML.load_file(config_file) if File.exists?(config_file) 
      default_config.merge(fc)
    end
  end

  private

  def compiler
    @compiler ||= indirection.terminus(config['compiler'])
  end

  # this is puppet's basic compiler that is used to
  # extract the facts and the node from the request
  def basic_compiler
    @basic_compiler ||= indirection.terminus(config['basic_compiler'])
  end

  def cm_cache
    @cm_cache ||= indirection.terminus(config['cm_cache'])
  end

  def invalidator
    @invalidator ||= begin
      invalidator_name = config['invalidator']
      Puppet::Util::Autoload.new(self,'puppet/cm_guard').load(invalidator_name)
      klass = "Puppet::CmGuard::#{Puppet::Indirector::Terminus.name2const(invalidator_name)}"
      constantize(klass).new
    end
  end

  # TODO: I assume there is some internal puppet code that does that for me,
  #       but I wasn't yet able to find it.
  def constantize(camel_cased_word)
    names = camel_cased_word.split('::')
    names.shift if names.empty? || names.first.empty?
    # go down the whole namespace
    names.inject(Object) do |constant,name|
      constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
    end
  end

  def default_config
    if Puppet.version =~ /^2\./ 
      {
        'compiler'        => 'compiler',
        'basic_compiler'  => 'compiler',
        'cm_cache'        => 'yaml_cm_guard',
        'invalidator'     => 'dummy_invalidator'
      }
    else
      {
        'compiler'        => 'static_compiler',
        'basic_compiler'  => 'compiler',
        'cm_cache'        => 'json_cm_guard',
        'invalidator'     => 'dummy_invalidator'
      }
    end
  end
end
