# frozen_string_literal: true

module SolidusFeeds
  module Publishers
    class StaticFile
      attr_reader :path

      def initialize(path:)
        @path = path
      end

      def call(&block)
        File.open(path, 'w', &block)
      end
    end
  end
end
