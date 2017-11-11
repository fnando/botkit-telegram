# frozen_string_literal: true

module Botkit
  module Telegram
    require "botkit"
    require "botkit/telegram/version"
    require "botkit/telegram/bot"
    require "botkit/telegram/message"

    def self.new(api_token:)
      Bot.new(api_token: api_token)
    end
  end
end
