# frozen_string_literal: true

require 'csv'

RSpec.describe SolidusFeeds::Publishers::S3 do
  let(:io) { StringIO.new }
  let(:client) { Aws::S3::Client.new(stub_responses: true) }
  let(:generator) {
    ->(io) {
      csv = CSV.new(io)
      csv << ["some", "data"]
      csv << ["another", "line"]
    }
  }

  describe '#call' do
    it 'correctly uploads the generated content to S3' do
      s3_publisher = described_class.new(object_key: 'my_feed.xml', bucket: 'dummy_bucket', client: client)

      response = s3_publisher.call do |io|
        generator.call(io)
      end

      expect(response).to be_instance_of(Aws::S3::Types::PutObjectOutput)
    end

    it 'raises an error if the generator does not generate anything' do
      s3_publisher = described_class.new(object_key: 'my_feed.xml', bucket: 'dummy_bucket', client: client)

      expect {
        s3_publisher.call do |io|
          io << ""
        end
      }.to raise_error SolidusFeeds::Publishers::S3::NoContentError
    end
  end
end
