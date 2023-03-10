# frozen_string_literal: true

require_relative "./spec_helper"

RSpec.describe(Jekyll::Commands::Publish) do
  let(:drafts_dir) { Pathname.new source_dir("_drafts") }
  let(:posts_dir) { Pathname.new source_dir("_posts") }
  let(:draft_to_publish) { "a-test-post.adoc" }
  let(:timestamp_format) { Jekyll::Compose::DEFAULT_TIMESTAMP_FORMAT }
  let(:date) { Time.now }
  let(:timestamp) { date.strftime(timestamp_format) }
  let(:datestamp) { date.strftime(Jekyll::Compose::DEFAULT_DATESTAMP_FORMAT) }
  let(:post_filename) { "#{datestamp}-#{draft_to_publish}" }
  let(:args) { ["_drafts/#{draft_to_publish}"] }

  let(:draft_path) { drafts_dir.join draft_to_publish }
  let(:post_path) { posts_dir.join post_filename }

  before(:all) do
    FileUtils.mkdir_p source_dir unless File.directory? source_dir
    Dir.chdir source_dir
  end

  before(:each) do
    FileUtils.mkdir_p drafts_dir unless File.directory? drafts_dir
    FileUtils.mkdir_p posts_dir unless File.directory? posts_dir
    File.write(draft_path, "---\nlayout: post\n---\n")
  end

  after(:each) do
    FileUtils.rm_r drafts_dir if File.directory? drafts_dir
    FileUtils.rm_r posts_dir if File.directory? posts_dir
    FileUtils.rm_r draft_path if File.file? draft_path
    FileUtils.rm_r post_path if File.file? post_path
  end

  it "publishes a draft post" do
    expect(post_path).not_to exist
    expect(draft_path).to exist
    capture_stdout { described_class.process(args) }
    expect(post_path).to exist
    expect(draft_path).not_to exist
    expect(File.read(post_path)).to include("date: #{timestamp}")
  end

  context "when date option is set" do
    let(:date) { Date.parse("2012-3-4") }

    it "publishes with a specified date" do
      expect(post_path).not_to exist
      expect(draft_path).to exist
      capture_stdout { described_class.process(args, "date" => "2012-3-4") }
      expect(post_path).to exist
      expect(draft_path).not_to exist
      expect(File.read(post_path)).to include("date: 2012-03-04")
    end

    context "and timestamp format is set" do
      let(:timestamp_format) { "%Y-%m-%d %H:%M:%S" }

      it "published with a specified date in a given format" do
        expect(post_path).not_to exist
        expect(draft_path).to exist
        capture_stdout { described_class.process(args, "date" => "2012-3-4", "timestamp_format" => timestamp_format) }
        expect(post_path).to exist
        expect(draft_path).not_to exist
        expect(File.read(post_path)).to include("date: '2012-03-04 00:00:00'")
      end
    end
  end

  it "writes a helpful message on success" do
    expect(draft_path).to exist
    output = capture_stdout { described_class.process(args) }
    expect(output).to include("Draft _drafts/#{draft_to_publish} was moved to _posts/#{post_filename}")
  end

  it "publishes a draft on the specified date" do
    path = posts_dir.join "2012-03-04-a-test-post.adoc"
    capture_stdout { described_class.process(args, "date" => "2012-3-4") }
    expect(path).to exist
    expect(draft_path).not_to exist
    expect(File.read(path)).to include("date: 2012-03-04")
  end

  it "creates the posts folder if necessary" do
    FileUtils.rm_r posts_dir if File.directory? posts_dir
    capture_stdout { described_class.process(args) }
    expect(posts_dir).to exist
  end

  it "errors if there is no argument" do
    expect(lambda {
      capture_stdout { described_class.process }
    }).to raise_error("You must specify a draft path.")
  end

  it "outputs a warning and returns if no file exists at given path" do
    weird_path = "_drafts/i-do-not-exist.markdown"
    output = capture_stdout { described_class.process [weird_path] }
    expect(output).to include("There was no draft found at '_drafts/i-do-not-exist.markdown'.")
    expect(draft_path).to exist
    expect(post_path).to_not exist
  end

  context "when the post already exists" do
    let(:args) { ["_drafts/#{draft_to_publish}"] }

    before(:each) do
      FileUtils.touch post_path
    end

    it "outputs a warning and returns" do
      output = capture_stdout { described_class.process(args) }
      expect(output).to include("A post already exists at _posts/#{post_filename}")
      expect(draft_path).to exist
      expect(post_path).to exist
    end

    it "overwrites if --force is given" do
      output = capture_stdout { described_class.process(args, "force" => true) }
      expect(output).to_not include("A post already exists at _posts/#{post_filename}")
      expect(draft_path).not_to exist
      expect(post_path).to exist
      expect(File.read(post_path)).to include("date: #{timestamp}")
    end
  end

  context "when a configuration file exists" do
    let(:config) { source_dir("_config.yml") }
    let(:drafts_dir) { Pathname.new source_dir("site", "_drafts") }
    let(:posts_dir) { Pathname.new source_dir("site", "_posts") }
    let(:config_data) do
      %(
    source: site
    )
    end

    before(:each) do
      File.write(config, config_data)
    end

    after(:each) do
      FileUtils.rm(config)
    end

    it "should use source directory set by config" do
      expect(post_path).not_to exist
      expect(draft_path).to exist
      capture_stdout { described_class.process(args) }
      expect(post_path).to exist
      expect(draft_path).not_to exist
    end
  end

  context "when source option is set" do
    let(:drafts_dir) { Pathname.new source_dir("site", "_drafts") }
    let(:posts_dir) { Pathname.new source_dir("site", "_posts") }

    it "should use source directory set by command line option" do
      expect(post_path).not_to exist
      expect(draft_path).to exist
      capture_stdout { described_class.process(args, "source" => "site") }
      expect(post_path).to exist
      expect(draft_path).not_to exist
    end
  end

  context "when timestamp format option is set" do
    context "to a custom value" do
      let(:timestamp_format) { "%Y-%m-%d %H:%M:%S" }

      it "should use timestamp format set by command line option" do
        expect(post_path).not_to exist
        expect(draft_path).to exist
        capture_stdout { described_class.process(args, "timestamp_format" => timestamp_format) }
        expect(post_path).to exist
        expect(draft_path).not_to exist
        expect(File.read(post_path)).to include("date: '#{timestamp}'")
      end
    end
    context "to the default value" do
      let(:timestamp_format) { Jekyll::Compose::DEFAULT_TIMESTAMP_FORMAT }

      it "should use timestamp format set by command line option" do
        expect(post_path).not_to exist
        expect(draft_path).to exist
        capture_stdout { described_class.process(args, "timestamp_format" => timestamp_format) }
        expect(post_path).to exist
        expect(draft_path).not_to exist
        expect(File.read(post_path)).to include("date: #{timestamp}")
      end
    end
  end
end
