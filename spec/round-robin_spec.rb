require "spec_helper"

describe "RoundRobin" do
  before(:each) do
    # Calling Resque.redis.redis looks weird, but it avoids a verbose
    # warning at the beginning of each spec example, because the wrapper object
    # returned by Resque.redis is namespaced, but the flushall command is not.
    Resque.redis.redis.flushall

    stub_const("ENV", env)

    5.times { |i| Resque::Job.create(:r_1, SomeJob, index: i) }
    5.times { |i| Resque::Job.create(:q_1, SomeJob, index: i) }
    5.times { |i| Resque::Job.create(:q_2, SomeJob, index: i) }
  end

  let(:env) { { "QUEUES" => "q_*,r_*" } }
  let(:worker) { Resque::Worker.new }

  describe "#process" do
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
      let(:env) do
        {
          "QUEUES" => "q_*,r_*",
          "JOBS_PER_FORK" => "4"
        }
      end

      it "processes 4 jobs from each queue and then switches round robin" do
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
  end

  describe "#perform_with_jobs_per_fork" do
    let(:env) do
      {
        "QUEUES" => "q_*,r_*",
        "JOBS_PER_FORK" => "4"
      }
    end
    let(:job) { worker.reserve_with_round_robin }

    before { worker.perform_with_jobs_per_fork(job) }

    it "reserves additional jobs from the same queue" do
      expect(Resque.size(:q_2)).to eq(1)
    end

    it "updates working state in redis" do
      expect(worker.job(:true)).to include(
        "queue" => "q_2",
        "payload" => {
          "class" => "SomeJob",
          "args"=>[{ "index"=>3 }]
        }
      )
    end
  end

  it "should pass lint" do
    Resque::Plugin.lint(Resque::Plugins::RoundRobin)
  end
end
