require "spec_helper"

describe "RoundRobin" do

  before(:each) do
    Resque.redis.flushall
    stub_const("ENV", { "QUEUES" => "q_*,r_*" })
  end

  context "a worker" do
    it "switches queues, round robin" do
      5.times { Resque::Job.create(:r_1, SomeJob) }
      5.times { Resque::Job.create(:q_1, SomeJob) }
      5.times { Resque::Job.create(:q_2, SomeJob) }

      worker = Resque::Worker.new

      worker.process
      Resque.size(:q_1).should == 5
      Resque.size(:q_2).should == 4
      Resque.size(:r_1).should == 5

      worker.process
      Resque.size(:q_1).should == 4
      Resque.size(:q_2).should == 4
      Resque.size(:r_1).should == 5

      8.times do
        worker.process
      end
      Resque.size(:q_1).should == 0
      Resque.size(:q_2).should == 0
      Resque.size(:r_1).should == 5
      worker.process
      Resque.size(:r_1).should == 4
    end

    it 'skips a queue that is being processed by another worker'
  end

  it "should pass lint" do
    Resque::Plugin.lint(Resque::Plugins::RoundRobin)
  end

end
