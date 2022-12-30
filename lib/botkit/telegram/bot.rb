# frozen_string_literal: true

module Botkit
  module Telegram
    class Bot < Botkit::Bot
      attr_reader :api_token, :booted_at
      attr_accessor :offset

      def initialize(api_token:)
        super()
        @api_token = api_token
        @booted_at = Time.now.utc.to_i
        @offset = 0
      end

      def call
        context = self

        response = Aitch.post do
          url "https://api.telegram.org/bot#{context.api_token}/getUpdates"
          params offset: context.offset,
                 allowed_updates: "message"
          options expect: 200
        end

        messages = response.data["result"]
        return if messages.empty?

        self.offset = messages.last["update_id"] + 1
        messages
          .reject {|message| message.key?("edited_message") }
          .select {|message| message.dig("message", "date") >= booted_at }
          .map(&method(:prepare_message))
          .each(&method(:handle_incoming_message))
      end

      def prepare_message(message)
        params = parse_message(message.dig("message", "text"))
        params = params.merge(raw: message,
                              channel_id: message.dig("message", "chat", "id"),
                              id: message.dig("message", "message_id"))
        Message.new(**params)
      end

      def send_message(message, options = {})
        context = self

        message_params = {
          text: message.text,
          chat_id: message.channel_id
        }.merge(options)

        Aitch.post do
          url "https://api.telegram.org/bot#{context.api_token}/sendMessage"
          params message_params
          options expect: 200
        end
      end

      def reply_message(message, reply, options = {})
        send_message(reply, options.merge(reply_to_message_id: message.id))
      end
    end
  end
end
