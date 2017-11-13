#
#    Copyright 2017, Optimizely and contributors
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
require 'spec_helper'
require 'optimizely/error_handler'
require 'optimizely/event_builder'
require 'optimizely/logger'
require 'optimizely/notification_center'

describe 'NotificationCenter' do
  config = nil
  let(:spy_logger) { spy('logger') }
  before(:context) do
    @config_body = OptimizelySpec::VALID_CONFIG_BODY
    @config_body_JSON = OptimizelySpec::VALID_CONFIG_BODY_JSON
    @error_handler = Optimizely::NoOpErrorHandler.new
    @logger = Optimizely::SimpleLogger.new

    class CallBack
      def call args
        return args
      end
    end

    @callback = CallBack.new
    @callback_reference = @callback.method(:call)

  end

  describe '#Notification center' do

    describe '.add_notification_listener' do
      it 'shoud return nil if notification type or is notification callback empty' do
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        expect(notification_center.add_notification_listener(
            nil,
            @callback_reference
        )).to eq(nil)
        expect(notification_center.add_notification_listener(
            Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION],
            nil
        )).to eq(nil)
        expect(spy_logger).to have_received(:log).once
                                  .with(Logger::ERROR, "Invalid notification type.")
        expect(spy_logger).to have_received(:log).once
                                  .with(Logger::ERROR, "Invalid notification callback.")
      end

      it 'shoud return 1 for valid params' do
        notification_center = Optimizely::NotificationCenter.new(Optimizely::SimpleLogger.new)
        expect(notification_center.add_notification_listener(
            Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION],
            @callback_reference
        )).to eq(1)
      end
      it 'shoud return -1 if callback already exists' do
        notification_center = Optimizely::NotificationCenter.new(Optimizely::SimpleLogger.new)
        notification_center.add_notification_listener(
            Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION],
            @callback_reference
        )
        expect(notification_center.add_notification_listener(
            Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION],
            @callback_reference
        )).to eq(-1)
      end
    end

    describe '.remove_notification_listener' do
      before(:example) do
        @notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        @notification_center = Optimizely::NotificationCenter.new(spy_logger)
        @notification_center.add_notification_listener(@notification_type, @callback_reference)
      end
      it 'shoud return nil if notification id is empty' do
        expect(@notification_center.remove_notification_listener(nil)).to eq(nil)
        expect(spy_logger).to have_received(:log).once
                                  .with(Logger::ERROR, "Notification id can't b empty.")
      end
      it 'shoud return true if notification is removed' do
        expect(@notification_center.remove_notification_listener(1)).to eq(true)
      end
      it 'shoud return false if notification failed to remove' do
        expect(@notification_center.remove_notification_listener(2)).to eq(false)
      end
    end


    describe '.clear_notifications' do

      it 'should return log of notifications cleared' do
        notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        notification_center.clear_notifications(notification_type)
        expect(spy_logger).to have_received(:log).once
          .with(Logger::INFO, "All callbacks for notification type #{notification_type} have been removed.")
      end
    end

    describe '.fire_notifications' do
      before(:example) do
        config = Optimizely::ProjectConfig.new(@config_body_JSON, @logger, @error_handler)
        @event_builder = Optimizely::EventBuilder.new(config)
        @args = [
            config.get_experiment_from_key('test_experiment'),
            'test_user',
            {},
            '111128',
            @event_builder.create_impression_event(
                config.get_experiment_from_key('test_experiment'),
                '111128', 'test_user', nil)
        ]
      end
      it 'should return success log for notification sent' do
        notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        notification_center.add_notification_listener(notification_type, @callback_reference)
        notification_center.fire_notifications(notification_type,@args)
        expect(spy_logger).to have_received(:log).once
          .with(Logger::INFO, "Notification #{notification_type} sent successfully.")
      end

      it 'should return nil if notification type not valid' do
        notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        notification_center.add_notification_listener(notification_type, @callback_reference)
        expect(notification_center.fire_notifications("test_type",@args)).to eq(nil)

      end
      it 'should return error when callback is invalid' do
        notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        notification_center.add_notification_listener(notification_type,@callback_reference)
        expect {notification_center.fire_notifications(undefined_variable,@args)}.to raise_error StandardError
      end

      it 'should return multiple logs of multiple notifications sent for same notification type' do

        class CallBackSecond
          def call args
            return "Test multi listner."
          end
        end

        @callback_second = CallBackSecond.new
        @callback_reference_second = @callback_second.method(:call)

        notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
        notification_center = Optimizely::NotificationCenter.new(spy_logger)
        notification_center.add_notification_listener(notification_type, @callback_reference)
        notification_center.add_notification_listener(notification_type, @callback_reference_second)

        notification_center.fire_notifications(notification_type,@args)
        expect(spy_logger).to have_received(:log).twice
                                  .with(Logger::INFO, "Notification #{notification_type} sent successfully.")
      end

    end
  end
end