# frozen_string_literal: true

#
#    Copyright 2018, Optimizely and contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'logger'
require 'optimizely'

class OptimizelyService
  @optimizely_client = nil

  class << self
    attr_accessor :optimizely_client
  end

  def initialize(datafile)
    @datafile = datafile
    @errors = []
  end

  def self.optimizely_client_present?
    @optimizely_client.present?
  end

  def instantiate!
    @logger = DemoLogger.new(Logger.new(STDOUT))
    @optimizely_client = Optimizely::Project.new(
      @datafile,
      Optimizely::EventDispatcher.new,
      @logger,
      nil,
      false
    )
    @errors.push('Invalid Optimizely client request!') unless @optimizely_client.is_valid
    @errors.empty?
  end

  def activate_service!(visitor, experiment_key)
    attributes = {}
    begin
      variation_key = @optimizely_client.activate(
        experiment_key,
        visitor['user_id'],
        attributes
      )
    rescue StandardError => error
      @errors.push(error.message)
    end
    [variation_key, @errors.empty?]
  end

  def track_service!(event_key, visitor, event_tags)
    attributes = {}
    begin
      @optimizely_client.track(
        event_key,
        visitor['user_id'],
        attributes,
        event_tags
      )
    rescue => e
      @errors.push(e.message)
    end
    @errors.empty?
  end

  def feature_enabled_service?(feature_flag_key, visitor)
    attributes = visitor['domain'].present? ? {'domain' => visitor['domain']} : {}
    begin
      enabled = @optimizely_client.is_feature_enabled(feature_flag_key, visitor['user_id'], attributes)
    rescue => e
      @errors.push(e.message)
    end
    [enabled, @errors.empty?]
  end

  def get_feature_variable_integer_service!(feature_flag_key, variable_key, visitor)
    attributes = visitor['domain'].present? ? {'domain' => visitor['domain']} : {'domain' => ''}
    begin
      discount_percentage = @optimizely_client.get_feature_variable_integer(
        feature_flag_key,
        variable_key,
        visitor['user_id'],
        attributes
      )
    rescue StandardError => error
      @errors.push(error.message)
    end
    [discount_percentage.to_i, @errors.empty?]
  end

  attr_reader :errors
end

class DemoLogger
  def initialize(logger)
    @logger = logger
  end

  def log(level = nil, message)
    @logger.info message
    LogMessage.create_record(level, message)
  end
end
