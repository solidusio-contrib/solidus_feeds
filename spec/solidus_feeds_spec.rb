require 'spec_helper'
require 'stringio'
require 'csv'

RSpec.describe SolidusFeeds do
  before { described_class.reset_config! }

  let(:io) { StringIO.new }
  let(:string_io_publisher) { ->(&block) { block.call(io) } }
  let(:csv_generator) {
    ->(io) {
      csv = CSV.new(io)
      csv << ["some", "data"]
      csv << ["another", "line"]
    }
  }

  it 'allows to register, generate, and publish feeds' do
    described_class.configure do |config|
      config.register :foo do |feed|
        feed.publisher = string_io_publisher
        feed.generator = csv_generator
      end
    end

    described_class.config.find(:foo).publish
    expect(io.string).to eq("some,data\nanother,line\n")
  end
end
