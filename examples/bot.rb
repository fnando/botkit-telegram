# frozen_string_literal: true

$LOAD_PATH << File.expand_path("#{__dir__}/../lib")
require "botkit-telegram"

class MyBot
  attr_reader :chatbot

  def initialize(api_token:)
    @chatbot = Botkit::Telegram.new(api_token: api_token)
    configure_bot
  end

  def configure_bot
    chatbot.command(:time, &method(:on_time))
    chatbot.command(:gem, &method(:on_gem))
    chatbot.message(&method(:on_message))
    chatbot.exception(&method(:on_exception))
  end

  def call
    Botkit.run(chatbot)
  end

  def on_time(message)
    text = "Now is <b>#{Time.now}</b>"
    message =
      Botkit::Telegram::Message.new(text: text, channel_id: message.channel_id)
    chatbot.send_message(message, parse_mode: "HTML")
  end

  def on_gem(message)
    GemCommand.new(message).call
  end

  def on_exception(error)
    $stderr << "#{error.class}: #{error.message}\n"
    $stderr << error.backtrace.join("\n")
    $stderr << "\n\n"
  end

  def on_message(message)
    reply = Botkit::Telegram::Message.new(
      text: "Sorry, but I don't know what you mean.",
      channel_id: message.channel_id
    )
    chatbot.reply_message(message, reply)
  end

  class GemCommand
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def call
      response = Aitch.get do
        url "https://rubygems.org/api/v1/gems/#{message.text}.json"
      end

      case response.code
      when 200
        send_gem_info(response)
      when 404
        send_gem_not_found
      else
        send_error
      end
    end

    def send_gem_info(response)
      gem_info = response.data
      name = gem_info["name"]
      description = gem_info["description"]
      project_uri = gem_info["project_uri"]

      text = [
        "<b>Info about #{name}</b>",
        "#{description}\n",
        project_uri
      ].join("\n")

      chatbot.send_message(
        Botkit::Telegram::Message.new(text: text),
        parse_mode: "HTML"
      )
    end

    def send_gem_not_found
      chatbot.send_message(
        Botkit::Telegram::Message.new(text: "Sorry! This gem doesn't exist.")
      )
    end

    def send_error
      chatbot.send_message(
        Botkit::Telegram::Message.new(text: "Sorry! Something went wrong.")
      )
    end
  end
end

MyBot.new(api_token: ENV.fetch("TELEGRAM_API_TOKEN")).call
