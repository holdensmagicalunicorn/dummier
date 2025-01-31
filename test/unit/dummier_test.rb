require_relative '../test_helper'

module HookTestHelper
  extend self
  
  def register(hook)
    hooks << hook
  end
  
  def hooks
    @hooks ||= []
  end  
  
end


class DummierTest < Test::Unit::TestCase

  def setup
    @root  = File.expand_path("../../dummy_gem", __FILE__)
    @dummy = File.join(@root, "test/dummy")
  end
  
  def read_file(file)
    File.read(File.join(@dummy, file))
  end

  should "have classes defined" do
    assert defined?(Dummier)
    assert defined?(Dummier::AppGenerator)
  end

  should "create test/dummy" do
    
    # remove existing dummy
    FileUtils.rm_r(@dummy) if File.exists?(@dummy)
    assert !File.exists?(@dummy)
        
    # create a generator
    @generator = Dummier::AppGenerator.new(@root)

    # make sure our gem's dummy_hooks/templates folder is accessible
    assert @generator.source_paths.include?(File.join(@root, "test/dummy_hooks/templates"))
    
    # run the generator
    @generator.run!

    # make sure the dummy is created
    assert File.exists?(@dummy)
    
    # make sure things that should get deleted do
    files = %w(public/index.html public/images/rails.png Gemfile README doc test vendor)
    files.each do |file|
      assert !File.exists?(file)
    end
    
    # make sure application template is applied
    rb = read_file('config/application.rb')
    [ "require File.expand_path('../boot', __FILE__)", /require "dummy_gem"/, /module Dummy/ ].each do |regex|
      assert_match regex, rb
    end
    
    # make sure boot template is applied
    rb = read_file('config/boot.rb')
    [ "gemfile = File.expand_path('../../../../Gemfile', __FILE__)", "ENV['BUNDLE_GEMFILE'] = gemfile", "$:.unshift File.expand_path('../../../../lib', __FILE__)" ].each do |regex|
      assert_match regex, rb
    end    
    
    # make sure hooks are all registered and in proper order
    assert_equal [:before_delete, :before_app_generator, :after_app_generator, :before_migrate, :after_migrate], HookTestHelper.hooks
    
  end

end