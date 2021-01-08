# frozen_string_literal: true

require 'csv'

RSpec.describe SolidusFeeds::Publishers::StaticFile do
  let(:filename) { 'my_feed.csv' }
  let(:io) { StringIO.new }
  let(:generator) {
    ->(io) {
      csv = CSV.new(io)
      csv << ["some", "data"]
      csv << ["another", "line"]
    }
  }

  describe '#call' do
    it 'saves the generated content to the specified file' do
      buffer = StringIO.new
      allow(File).to receive(:open).with(filename, 'w').and_yield(buffer)
      static_file_publisher = described_class.new(path: filename)

      static_file_publisher.call do |io|
        generator.call(io)
      end

      expect(buffer.string).to eq(
        "some,data\nanother,line\n"
      )
    end
  end
end
