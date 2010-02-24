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
end

describe Kernel do
  context "#revenant" do
    it "returns a Revenant::Task instance with the given name" do
      task = revenant(:wrath)
      task.should be_instance_of(Revenant::Task)
      task.name.should == :wrath
    end
  end
end
