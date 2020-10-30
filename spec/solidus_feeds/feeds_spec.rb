require 'spec_helper'
require 'stringio'
require 'csv'

RSpec.describe SolidusFeeds::Feeds do
  subject(:solidus_feeds) { Class.new.tap { |klass| klass.extend described_class } }

  let(:io) { StringIO.new }
  let(:publisher) { ->(&block) { block.call(io) } }
  let(:generator) {
    ->(io) {
      csv = CSV.new(io)
      csv << ["some", "data"]
      csv << ["another", "line"]
    }
  }

  it 'allows to register, generate, and publish feeds' do
    solidus_feeds.register :foo do |feed|
      feed.publisher = publisher
      feed.generator = generator
    end

    feed = solidus_feeds.find(:foo)
    feed.publish

    expect(feed).to be_a SolidusFeeds::Feed
    expect(io.string).to eq("some,data\nanother,line\n")
  end
end
