# DO NOT MODIFY THIS FILE

require 'digest/sha1'
require 'rubygems'

module Gem
  class Dependency
    if !instance_methods.map { |m| m.to_s }.include?("requirement")
      def requirement
        version_requirements
      end
    end
  end
end

module Bundler
  module SharedHelpers

    def default_gemfile
      gemfile = find_gemfile
      gemfile or raise GemfileNotFound, "The default Gemfile was not found"
      Pathname.new(gemfile)
    end

    def in_bundle?
      find_gemfile
    end

  private

    def find_gemfile
      return ENV['BUNDLE_GEMFILE'] if ENV['BUNDLE_GEMFILE']

      previous = nil
      current  = File.expand_path(Dir.pwd)

      until !File.directory?(current) || current == previous
        filename = File.join(current, 'Gemfile')
        return filename if File.file?(filename)
        current, previous = File.expand_path("..", current), current
      end
    end

    def clean_load_path
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        me = File.expand_path("../../", __FILE__)
        $LOAD_PATH.reject! do |p|
          next if File.expand_path(p).include?(me)
          p != File.dirname(__FILE__) &&
            Gem.path.any? { |gp| p.include?(gp) }
        end
        $LOAD_PATH.uniq!
      end
    end

    def reverse_rubygems_kernel_mixin
      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias rubygems_require require
          alias require gem_original_require
        end

        undef gem
      end
    end

    def cripple_rubygems(specs)
      reverse_rubygems_kernel_mixin

      executables = specs.map { |s| s.executables }.flatten

     :: Kernel.class_eval do
        private
        def gem(*) ; end
      end
      Gem.source_index # ensure RubyGems is fully loaded

      ::Kernel.send(:define_method, :gem) do |dep, *reqs|
        if executables.include? File.basename(caller.first.split(':').first)
          return
        end
        opts = reqs.last.is_a?(Hash) ? reqs.pop : {}

        unless dep.respond_to?(:name) && dep.respond_to?(:requirement)
          dep = Gem::Dependency.new(dep, reqs)
        end

        spec = specs.find  { |s| s.name == dep.name }

        if spec.nil?
          e = Gem::LoadError.new "#{dep.name} is not part of the bundle. Add it to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.requirement
          raise e
        elsif dep !~ spec
          e = Gem::LoadError.new "can't activate #{dep}, already activated #{spec.full_name}. " \
                                 "Make sure all dependencies are added to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.requirement
          raise e
        end

        true
      end

      # === Following hacks are to improve on the generated bin wrappers ===

      # Yeah, talk about a hack
      source_index_class = (class << Gem::SourceIndex ; self ; end)
      source_index_class.send(:define_method, :from_gems_in) do |*args|
        source_index = Gem::SourceIndex.new
        source_index.spec_dirs = *args
        source_index.add_specs(*specs)
        source_index
      end

      # OMG more hacks
      gem_class = (class << Gem ; self ; end)
      gem_class.send(:define_method, :bin_path) do |name, *args|
        exec_name, *reqs = args

        spec = nil

        if exec_name
          spec = specs.find { |s| s.executables.include?(exec_name) }
          spec or raise Gem::Exception, "can't find executable #{exec_name}"
        else
          spec = specs.find  { |s| s.name == name }
          exec_name = spec.default_executable or raise Gem::Exception, "no default executable for #{spec.full_name}"
        end

        gem_bin = File.join(spec.full_gem_path, spec.bindir, exec_name)
        gem_from_path_bin = File.join(File.dirname(spec.loaded_from), spec.bindir, exec_name)
        File.exist?(gem_bin) ? gem_bin : gem_from_path_bin
      end
    end

    extend self
  end
end

module Bundler
  LOCKED_BY    = '0.9.14'
  FINGERPRINT  = "b899d469263bdee67f59c486fc437bca35d5e3b1"
  AUTOREQUIRES = {:test=>[["active_support", true], ["rack/test", true], ["capybara", false], ["dice", false], ["do_sqlite3", false], ["factory_girl", false], ["factory_girl_extensions", false], ["spec", true]], :default=>[["data_objects", false], ["datamapper", false], ["do_postgres", false], ["haml", false], ["sinatra/base", true]]}
  SPECS        = [
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/rake-0.8.7/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/rake-0.8.7.gemspec", :name=>"rake"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/activesupport-2.3.5/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/activesupport-2.3.5.gemspec", :name=>"activesupport"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/addressable-2.1.1/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/addressable-2.1.1.gemspec", :name=>"addressable"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/bcrypt-ruby-2.1.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/bcrypt-ruby-2.1.2.gemspec", :name=>"bcrypt-ruby"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/culerity-0.2.9/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/culerity-0.2.9.gemspec", :name=>"culerity"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/mime-types-1.16/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/mime-types-1.16.gemspec", :name=>"mime-types"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/nokogiri-1.4.1/lib", "/usr/lib/ruby/gems/1.8/gems/nokogiri-1.4.1/ext"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/nokogiri-1.4.1.gemspec", :name=>"nokogiri"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/rack-1.1.0/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/rack-1.1.0.gemspec", :name=>"rack"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/rack-test-0.5.3/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/rack-test-0.5.3.gemspec", :name=>"rack-test"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/ffi-0.6.3/lib", "/home/remi/.bundle/ruby/1.8/gems/ffi-0.6.3/ext"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/ffi-0.6.3.gemspec", :name=>"ffi"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/json_pure-1.2.3/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/json_pure-1.2.3.gemspec", :name=>"json_pure"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/selenium-webdriver-0.0.17/common/src/rb/lib", "/usr/lib/ruby/gems/1.8/gems/selenium-webdriver-0.0.17/firefox/src/rb/lib", "/usr/lib/ruby/gems/1.8/gems/selenium-webdriver-0.0.17/chrome/src/rb/lib", "/usr/lib/ruby/gems/1.8/gems/selenium-webdriver-0.0.17/jobbie/src/rb/lib", "/usr/lib/ruby/gems/1.8/gems/selenium-webdriver-0.0.17/remote/client/src/rb/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/selenium-webdriver-0.0.17.gemspec", :name=>"selenium-webdriver"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/capybara-0.3.6/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/capybara-0.3.6.gemspec", :name=>"capybara"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/data_objects-0.10.1/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/data_objects-0.10.1.gemspec", :name=>"data_objects"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/extlib-0.9.14/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/extlib-0.9.14.gemspec", :name=>"extlib"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-core-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-core-0.10.2.gemspec", :name=>"dm-core"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-aggregates-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-aggregates-0.10.2.gemspec", :name=>"dm-aggregates"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-constraints-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-constraints-0.10.2.gemspec", :name=>"dm-constraints"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-migrations-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-migrations-0.10.2.gemspec", :name=>"dm-migrations"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/fastercsv-1.5.3/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/fastercsv-1.5.3.gemspec", :name=>"fastercsv"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-serializer-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-serializer-0.10.2.gemspec", :name=>"dm-serializer"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-timestamps-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-timestamps-0.10.2.gemspec", :name=>"dm-timestamps"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/stringex-1.1.0/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/stringex-1.1.0.gemspec", :name=>"stringex"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/uuidtools-2.1.1/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/uuidtools-2.1.1.gemspec", :name=>"uuidtools"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-types-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-types-0.10.2.gemspec", :name=>"dm-types"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dm-validations-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dm-validations-0.10.2.gemspec", :name=>"dm-validations"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/datamapper-0.10.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/datamapper-0.10.2.gemspec", :name=>"datamapper"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/dice-0.0.3/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/dice-0.0.3.gemspec", :name=>"dice"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/do_postgres-0.10.1/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/do_postgres-0.10.1.gemspec", :name=>"do_postgres"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/do_sqlite3-0.10.1.1/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/do_sqlite3-0.10.1.1.gemspec", :name=>"do_sqlite3"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/factory_girl-1.2.4/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/factory_girl-1.2.4.gemspec", :name=>"factory_girl"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/factory_girl_extensions-0.3.2/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/factory_girl_extensions-0.3.2.gemspec", :name=>"factory_girl_extensions"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/haml-2.2.22/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/haml-2.2.22.gemspec", :name=>"haml"},
        {:load_paths=>["/usr/lib/ruby/gems/1.8/gems/rspec-1.3.0/lib"], :loaded_from=>"/usr/lib/ruby/gems/1.8/specifications/rspec-1.3.0.gemspec", :name=>"rspec"},
        {:load_paths=>["/home/remi/.bundle/ruby/1.8/gems/sinatra-1.0/lib"], :loaded_from=>"/home/remi/.bundle/ruby/1.8/specifications/sinatra-1.0.gemspec", :name=>"sinatra"},
      ].map do |hash|
    if hash[:virtual_spec]
      spec = eval(hash[:virtual_spec], binding, "<virtual spec for '#{hash[:name]}'>")
    else
      dir = File.dirname(hash[:loaded_from])
      spec = Dir.chdir(dir){ eval(File.read(hash[:loaded_from]), binding, hash[:loaded_from]) }
    end
    spec.loaded_from = hash[:loaded_from]
    spec.require_paths = hash[:load_paths]
    spec
  end

  extend SharedHelpers

  def self.configure_gem_path_and_home(specs)
    # Fix paths, so that Gem.source_index and such will work
    paths = specs.map{|s| s.installation_path }
    paths.flatten!; paths.compact!; paths.uniq!; paths.reject!{|p| p.empty? }
    ENV['GEM_PATH'] = paths.join(File::PATH_SEPARATOR)
    ENV['GEM_HOME'] = paths.first
    Gem.clear_paths
  end

  def self.match_fingerprint
    print = Digest::SHA1.hexdigest(File.read(File.expand_path('../../Gemfile', __FILE__)))
    unless print == FINGERPRINT
      abort 'Gemfile changed since you last locked. Please `bundle lock` to relock.'
    end
  end

  def self.setup(*groups)
    match_fingerprint
    clean_load_path
    cripple_rubygems(SPECS)
    configure_gem_path_and_home(SPECS)
    SPECS.each do |spec|
      Gem.loaded_specs[spec.name] = spec
      $LOAD_PATH.unshift(*spec.require_paths)
    end
  end

  def self.require(*groups)
    groups = [:default] if groups.empty?
    groups.each do |group|
      (AUTOREQUIRES[group.to_sym] || []).each do |file, explicit|
        if explicit
          Kernel.require file
        else
          begin
            Kernel.require file
          rescue LoadError
          end
        end
      end
    end
  end

  # Setup bundle when it's required.
  setup
end
