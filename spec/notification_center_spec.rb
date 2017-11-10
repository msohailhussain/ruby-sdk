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
require 'optimizely'
require 'optimizely/logger'
require 'optimizely/notification_center'

describe 'NotificationCenter' do
  let(:spy_logger) { spy('logger') }

  # describe '.cast_value_to_type' do
  #   it 'should return 1 for adding new notification_listener' do
  #     notification_center = Optimizely::NotificationCenter.new(Optimizely::SimpleLogger.new)
  #     notification_type = Optimizely::NotificationCenter::NOTIFICATION_TYPES[:DECISION]
  #     callback = "Hello Message!"
  #     notification_center.add_notification_listener(notification_type, callback).to eq(1)
  #   end
  #
  # end
end
