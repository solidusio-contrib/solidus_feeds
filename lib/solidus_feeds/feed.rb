# frozen_string_literal: true

class SolidusFeeds::Feed
  attr_accessor :generator, :publisher

  def initialize
    yield(self) if block_given?
  end

  def generate(output)
    generator.call(output)
  end

  def publish
    publisher.call do |output|
      generate(output)
    end
  end
end
