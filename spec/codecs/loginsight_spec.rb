# encoding: utf-8
# Copyright © 2017 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/loginsight"
require "logstash/event"
require "logstash/json"
require "logstash/timestamp"

describe LogStash::Codecs::LogInsight do
  subject do
    LogStash::Codecs::LogInsight.new
  end

  context "#map_loginsight_messages" do
    it "works" do
      message = {"text" => "message body"}

      expect { |b|
        subject.send(:map_loginsight_messages, message, &b)
      }.to yield_control.exactly(1).times

      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
      end
    end

    it "honors existing milliseconds-since-epoch timestamp" do
      message = {"timestamp" => "5000"}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("@timestamp")).to be_a(LogStash::Timestamp)
        expect(event.get("@timestamp").to_i).to eql(5)  # 5000 ms == 5 seconds
      end
    end

    it "adds missing timestamp" do
      message = {"text" => "message body"}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("@timestamp")).to be_a(LogStash::Timestamp)
        expect(event.get("message")).to eql("message body")
      end
    end

    it "maps arbitrary fields" do
      message = {"text"=>"message body", "fields"=>[{"name"=>"hostname", "content"=>"172.16.44.1", "startPosition"=>-1, "length"=>-2147483648}, {"name"=>"extratag", "content"=>"5", "startPosition"=>-1, "length"=>-2147483648}, {"name"=>"__li_source_path", "content"=>"172.16.44.1", "startPosition"=>-1, "length"=>-2147483648}]}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("@timestamp")).to be_a(LogStash::Timestamp)
        expect(event.get("message")).to eql("message body")
        expect(event.get("hostname")).to eql("172.16.44.1")
        expect(event.get("__li_source_path")).to eql("172.16.44.1")
        expect(event.get("extratag")).to eql("5")
      end
    end

    it "preserves an existing 'message' field" do
      message = {"text"=>"message body", "fields"=>[{"name"=>"message", "content"=>"message tag"}]}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("message")).to eql(message["text"])
        expect(event.get("_message")).to eql(message["fields"][0]["content"]["message tag"])
      end
    end

    it "handles missing 'message' field" do
      message = {"fields"=>[{"name"=>"foo", "content"=>"bar"}]}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("message")).to eql(nil)
      end
    end

    it "ignores other fields" do
      message = {"foo"=>"bar"}
      subject.send(:map_loginsight_messages, message) do |event|
        expect(event).to be_a(LogStash::Event)
        expect(event.get("message")).to eql(nil)
        expect(event).not_to include("foo")
      end
    end

  end

  context "#decode" do

    it "silently yields no events for an empty input messages list" do
      data = {"messages" => []}
      expect { |b|
        subject.decode(LogStash::Json.dump(data), &b)
      }.to yield_control.exactly(0).times
    end

    describe "passes through unknown, but valid json" do
      shared_examples "given" do |value_arg|
        context "where input is '#{value_arg}'" do
          let(:value) { value_arg }
          let(:event) do
            e = nil
            subject.decode(LogStash::Json.dump(value)) do |decoded|
              e = decoded
            end
            e
          end

          it "stores the value in 'message'" do
            expect(event.get("message")).to eql(value)
          end

          it "adds the _eventparsefailure tag" do
            expect(event.get("tags")).to include("_eventparsefailure")
          end
        end
      end

      include_examples "given", 123
      include_examples "given", "scalar"
      include_examples "given", "-1"
      include_examples "given", " "
      include_examples "given", {"foo" => "bar"}
      include_examples "given", [{"foo" => "bar"}]
      include_examples "given", {"foo" => "bar", "baz" => {"quux" => ["a","b","c"]}}

    end

    describe "cannot parse json" do
      shared_examples "json" do |value_arg|
        context "where input is '#{value_arg}'" do
          let(:value) { value_arg }
          let(:event) do
            e = nil
            subject.decode(value) do |decoded|
              e = decoded
            end
            e
          end

          it "stores the value in 'message'" do
            expect(event.get("message")).to eql(value)
          end

          it "adds the failure tag" do
            expect(event).to include "tags"
          end

          it "uses an array to store the tags" do
            expect(event.get("tags")).to be_a Array
          end

          it "adds the _jsonparsefailure tag" do
            expect(event.get("tags")).to include("_jsonparsefailure")
          end
        end
      end

      include_examples "json", "scalar"
      include_examples "json", 'random_{message'
      include_examples "json", "{"
      include_examples "json", "[{]"
    end

  end

end
