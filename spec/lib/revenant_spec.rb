require 'spec_helper'

describe Revenant do
  context ".find_module" do
    it "finds a lock module by name" do
      Revenant.find_module("mysql").should == Revenant::MySQL
    end

    it "raises ArgumentError if no such module is found" do
      lambda do
        Revenant.find_module("zazzy")
      end.should raise_error(ArgumentError)
    end
  end

  context ".register" do
    before do
      module BadLock
      end

      module SpecLock
        def self.lock_function; proc { true }; end
      end
    end

    it "raises if the module does not provide a lock function" do
      lambda do
        Revenant.register("bad", BadLock)
      end.should raise_error(ArgumentError)
    end

    it "adds a new lock type" do
      Revenant.register("spec", SpecLock)
      Revenant.find_module("spec").should == SpecLock
    end

    it "replaces an existing module with the same name" do
      Revenant.register("spec", SpecLock)
      Revenant.register("spec", Revenant::MySQL)
      Revenant.find_module("spec").should == Revenant::MySQL
    end

  end
end

describe Kernel do
  context "#revenant" do
    it "returns a Revenant::Task instance with the given name" do
      task = revenant(:wrath)
      task.should be_instance_of(Revenant::Task)
      task.name.should == :wrath
    end

    it "raises if a bad name is given" do
      lambda do
        task = revenant(5)
      end.should raise_error(ArgumentError)
    end

    it "yields the new Task if a block is given" do
      task = nil
      revenant("spec") do |t|
        task = t
      end
      task.should be_instance_of(Revenant::Task)
      task.name.should == :spec
    end

    it "defaults to enabling the 'daemon' option" do
      task = revenant(:example)
      task.options[:daemon].should == true
      task.daemon?.should == true
    end
  end
end
