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
module Optimizely
  class NotificationCenter
    NOTIFICATION_TYPES = {
      DECISION: 'DECISION: experiment, user_id, attributes, variation, event',
      TRACK: 'TRACK: event_key, user_id, attributes, event_tags, event',
      FEATURE_ACCESSED: 'FEATURE: feature_key, user_id, attributes, variation'
    }

    def initialize(logger)
      @notification_id = 1
      @notifications = {}
						NOTIFICATION_TYPES.values.each { |value| @notifications[value] = [] }
      @logger = logger
    end

    def add_notification_listener(notification_type, notification_callback)
      # Add a notification callback to the notification center.

      # Args:
      #   notification_type: DECISION
      #   notification_callback: closure of function to call when event is triggered.

      # Returns:
      #  notification id used to remove the notification

      unless notification_type
        @logger.log Logger::ERROR, 'Notification type can not be blank!'
        return nil
      end

      unless notification_callback
        @logger.log Logger::ERROR, 'Callback can not be blank!'
        return nil
      end

      unless notification_callback.is_a? Method
        @logger.log Logger::ERROR, "#{notification_callback} is invalid."
        return nil
      end
						
      if @notifications.include?(notification_type)
        @notifications[notification_type].each do |notification|
          return -1 if notification[:callback] == notification_callback
        end
        @notifications[notification_type].push ({notification_id: @notification_id, callback: notification_callback})
      else
								@logger.log Logger::ERROR, 'Invalid notification type.'
								return nil
      end
      notification_id = @notification_id
      @notification_id += 1
      notification_id
    end

    def remove_notification_listener(notification_id)
      # Remove a previously added notification callback.

      # Args:
      #     notification_id:
      # Returns:
      #     The function returns true if found and removed, false otherwise.

      unless notification_id
        @logger.log Logger::ERROR, "Notification id can not be blank!"
        return nil
						end
      @notifications.each do |key, _array|
        @notifications[key].each do |notification|
										if notification_id == notification[:notification_id]
            @notifications[key].delete(notification_id: notification_id, callback: notification[:callback])
            return true
          end
        end
						end
      false
    end

    def clear_notifications(notification_type)
      # Remove notifications for a certain notification type
      #
      # Args:
      #     notification_type: key to the list of notifications .helpers.enums.NotificationTypes
      @notifications[notification_type] = []
						@logger.log Logger::INFO, "All callbacks for notification type #{notification_type} have been removed."
    end

    def fire_notifications(notification_type, *args)
      # Fires off the notification for the specific event.  Uses var args to pass in a
      # arbitrary list of parameter according to which notification type was fired.

      # Args:
      # notification_type: Type of notification to fire.
      # args: list of arguments to the callback.
      if @notifications.include?(notification_type)
        @notifications[notification_type].each do |notification|
          begin
            notification_callback = notification[:callback]
            notification_callback.call *args
            @logger.log Logger::INFO, "Notification #{notification_type} sent successfully."
          rescue => e
            @logger.log(Logger::ERROR, "Problem calling notify callback. Error: #{e}")
            return nil
          end
        end
      end
    end
  end
end
