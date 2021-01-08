# frozen_string_literal: true

module SolidusFeeds
  module Publishers
    class StaticFile
      attr_reader :path

      def initialize(path:)
        @path = path
      end

      def call
        File.open(path, 'w') do |file|
          yield file
        end
      end
    end
  end
end
