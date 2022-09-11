require "spec_helper"

describe "RoundRobin" do
  before(:each) do
    Resque.redis.redis.flushall

    5.times { |i| Resque::Job.create(:r_1, SomeJob, index: i) }
    5.times { |i| Resque::Job.create(:q_1, SomeJob, index: i) }
    5.times { |i| Resque::Job.create(:q_2, SomeJob, index: i) }

    stub_const("ENV", env)
  end

  let(:env) { { "QUEUES" => "q_*,r_*" } }
  let(:worker) { Resque::Worker.new }

  context "with default job forking" do
    it "switches queues, round robin" do
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
  end

  context "with multiple jobs per fork" do
    before do
      # There is code that depends on env vars being present when the plugin is
      # included, so force a new include
      Resque::Worker.send(:include, Resque::Plugins::RoundRobin)
    end

    let(:env) do
      {
        "QUEUES" => "q_*,r_*",
        "JOBS_PER_FORK" => "4"
      }
    end

    it "switches queues round robin, processing 4 jobs at a time" do
      worker.process
      expect(Resque.size(:q_2)).to eq(1)
      expect(Resque.size(:q_1)).to eq(5)
      expect(Resque.size(:r_1)).to eq(5)
      expect(worker.job(true)).to be_empty

      worker.process
      expect(Resque.size(:q_2)).to eq(1)
      expect(Resque.size(:q_1)).to eq(1)
      expect(Resque.size(:r_1)).to eq(5)
      expect(worker.job(true)).to be_empty

      worker.process
      expect(Resque.size(:q_2)).to eq(1)
      expect(Resque.size(:q_1)).to eq(0)
      expect(Resque.size(:r_1)).to eq(5)
      expect(worker.job(true)).to be_empty

      worker.process
      expect(Resque.size(:q_2)).to eq(0)
      expect(Resque.size(:q_1)).to eq(0)
      expect(Resque.size(:r_1)).to eq(5)
      expect(worker.job(true)).to be_empty

      worker.process
      expect(Resque.size(:q_2)).to eq(0)
      expect(Resque.size(:q_1)).to eq(0)
      expect(Resque.size(:r_1)).to eq(1)
      expect(worker.job(true)).to be_empty
    end
  end

  it "should pass lint" do
    Resque::Plugin.lint(Resque::Plugins::RoundRobin)
  end
end
