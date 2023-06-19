# encoding: utf-8
# Copyright © 2017 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/json"
require "logstash/event"
require "logstash/timestamp"

# This codec may be used to decode (via inputs) JSON-encoded messages,
# with timestamp and key=value fields, from VMware vRealize Log Insight via CFAPI.
#
# If this codec recieves a payload from an input that is not valid JSON,
# then it it will add a tag `_jsonparsefailure` with the payload stored
# in the `message` field.
#
# If this codec receives a payload from an input that is valid JSON,
# but which is not structured as Log Insight is expected to produce,
# then it will add a tag `_eventparsefailure` with the payload stored
# in the `message` field.
#
# input { http { port=>9000 additional_codecs=>{ "application/json" => "loginsight"} } }

class LogStash::Codecs::LogInsight < LogStash::Codecs::Base
  config_name "loginsight"

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252".
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  def decode(data, &block)
    parse(@converter.convert(data), &block)
  end

  private
  
  def map_loginsight_messages(item, &block)
    # map the fields and values to a hash, preserving an existing `message`
    begin
      event_hash = Hash[item["fields"].map { |f| [f["name"], f["content"]] }]
      if event_hash.has_key?("message")
        event_hash["_message"] = event_hash["message"]
      end
    rescue
      event_hash = {}
    end

    # Add the message field, so it overwrites the above
    event = LogStash::Event.new(event_hash.merge("message" => item["text"]))

    # Make a Timestamp object from the source message (UTC Epoch in Milliseconds).
    begin
      newtime = LogStash::Timestamp.at( item["timestamp"].to_i / 1000.0 )
      event.set( LogStash::Event::TIMESTAMP, newtime )
    rescue
      event.set( LogStash::Event::TIMESTAMP_FAILURE_FIELD, item["timestamp"])
    end

    yield event
  end

  def parse(json, &block)
    decoded = LogStash::Json.load(json)

    case decoded
    when Hash
      @logger.debug("parse handling hash", :decoded => decoded)

      if decoded.has_key?("messages") and decoded["messages"].kind_of?(Array)
        decoded["messages"].each { |item|
          begin
            map_loginsight_messages(item, &block)
          rescue StandardError => e
            @logger.error("Event parse failure.", :error => e, :item => item)
            yield LogStash::Event.new("message" => item, "tags" => ["_eventparsefailure"])
          end
        }  # end decoded["message"].each
      else
        @logger.error("Log Insight codec expects 'messages' to contain an array", :data => json)
        yield LogStash::Event.new("message" => decoded, "tags" => ["_eventparsefailure"])
      end
    else
      @logger.error("Log Insight expeects a hash containing 'messages'", :data => json)
      yield LogStash::Event.new("message" => decoded, "tags" => ["_eventparsefailure"])
    end
  rescue LogStash::Json::ParserError => e
    @logger.error("JSON parse failure.", :error => e, :data => json)
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  rescue StandardError => e
    # This should NEVER happen.
    @logger.warn(
      "An unexpected error occurred parsing JSON data",
      :data => json,
      :message => e.message,
      :class => e.class.name,
      :backtrace => e.backtrace
    )
  end
end
