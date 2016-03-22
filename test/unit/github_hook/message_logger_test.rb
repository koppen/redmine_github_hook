# require 'test_helper'
require "minitest/autorun"
require_relative "../../../app/services/github_hook/message_logger"

class MessageLoggerTest < Minitest::Test
  def setup
    @logger = GithubHook::MessageLogger.new
  end

  def test_adds_messages_to_an_array
    logger.info "Testing"
    assert_equal [
      {:level => "info", :message => "Testing"}
    ], logger.messages
  end

  def test_supports_standard_log_levels
    levels = ["fatal", "error", "warn", "info", "debug"]
    levels.each do |level|
      logger.public_send(level, level)
    end
    assert_equal levels, logger.messages.map { |m| m[:level] }
  end

  def test_supports_blocks
    logger.debug { "This is my message" }
    assert_equal [
      {:level => "debug", :message => "This is my message"}
    ], logger.messages
  end

  def test_logs_to_a_wrapped_logger_as_well
    wrapped_logger = GithubHook::MessageLogger.new
    logger = GithubHook::MessageLogger.new(wrapped_logger)
    logger.debug "This goes everywhere"
    assert_equal [
      :level => "debug", :message => "This goes everywhere"
    ], logger.messages
    assert_equal [
      :level => "debug", :message => "This goes everywhere"
    ], wrapped_logger.messages
  end

  private

  def logger
    @logger ||= GithubHook::MessageLogger.new
  end
end
