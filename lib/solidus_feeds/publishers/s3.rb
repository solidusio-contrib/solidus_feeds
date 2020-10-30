# frozen_string_literal: true

require 'aws-sdk-s3'

module SolidusFeeds
  module Publishers
    class S3
      attr_reader :object_key, :bucket, :resource

      NoContentError = Class.new(StandardError)

      def initialize(object_key:, bucket:, client: Aws::S3::Client.new)
        @object_key = object_key
        @bucket = bucket
        @resource = Aws::S3::Resource.new(client: client)
      end

      def call
        Tempfile.create(object_key) do |io|
          yield io
          io.rewind
          raise NoContentError, "no content was generated" if io.eof?

          object = resource.bucket(bucket).object(object_key)
          object.put(body: io, acl: 'public-read')
        end
      end
    end
  end
end
