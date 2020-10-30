# frozen_string_literal: true

module SolidusFeeds::Feeds
  def feeds
    @feeds ||= {}
  end

  def register(name, &block)
    feeds[name] = block
  end

  def find(name)
    SolidusFeeds::Feed.new.tap { |feed| feeds[name].call(feed) }
  end

  SolidusFeeds.extend self
end
