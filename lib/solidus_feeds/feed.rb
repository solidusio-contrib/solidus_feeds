# frozen_string_literal: true

class SolidusFeeds::Feed
  attr_accessor :generator, :publisher

  def generate(output)
    generator.call(output)
  end

  def publish
    publisher.call do |output|
      generate(output)
    end
  end
end
