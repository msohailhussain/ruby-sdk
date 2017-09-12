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
require 'optimizely/logger'
require 'optimizely/helpers/validator'

module Optimizely
  module Helpers
    module EventTagUtils
      module_function

      REVENUE_EVENT_METRIC_NAME = 'revenue';
      VALUE_EVENT_METRIC_NAME = 'value';

      # Grab the revenue value from the event tags. "revenue" is a reserved keyword.
      # Params:
      # +event_tags+:: +Hash+ representing metadata associated with the event.
      # Returns:
      # +Integer+ | +nil+ if revenue can't be retrieved from the event tags.
      def get_revenue_value(event_tags)
        revenue_value = nil
        
        if ( event_tags and Helpers::Validator.attributes_valid?(event_tags) and event_tags.has_key?(REVENUE_EVENT_METRIC_NAME) )
  
          logger = SimpleLogger.new
  
          begin
            raw_value = event_tags[REVENUE_EVENT_METRIC_NAME]

            if raw_value.is_a? Numeric
              num_value = raw_value
            else
              num_value = raw_value.to_i
            end

            if (!num_value.is_a?(Float)) and num_value.to_s == raw_value.to_s
              revenue_value = raw_value
              logger.log(Logger::INFO, "Parsed revenue value #{raw_value} from event tags.")
            else
              logger.log(Logger::WARN, "Failed to parse revenue value #{raw_value} from event tags.")
            end

          rescue
            logger.log(Logger::WARN, "Failed to parse revenue value #{raw_value} from event tags.")
          end

        end

        revenue_value
      end

      # Grab the event value from the event tags. "value" is a reserved keyword.
      # Params:
      # +event_tags+:: +Hash+ representing metadata associated with the event.
      # Returns:
      # +Number+ | +nil+ if value can't be retrieved from the event tags.
      def get_event_value(event_tags)
        event_value = nil

        if ( event_tags and Helpers::Validator.attributes_valid?(event_tags) and event_tags.has_key?(VALUE_EVENT_METRIC_NAME) )

          logger = SimpleLogger.new

          begin
            raw_value = event_tags[VALUE_EVENT_METRIC_NAME]

            if raw_value.is_a? Numeric
              num_value = raw_value
            else
              i = raw_value.to_i
              f = raw_value.to_f
              num_value = i == f ? i : f
            end

            if num_value.to_s ==  raw_value.to_s # Insuring value was not rounded during conversion to number
              event_value = num_value
              logger.log(Logger::INFO, "Parsed event value #{raw_value} from event tags.")
            else
              logger.log(Logger::WARN, "Failed to parse event value #{raw_value} from event tags.")
            end
          rescue
            logger.log(Logger::WARN, "Failed to parse event value #{raw_value} from event tags.")
          end

        end

        return event_value
      end

    end
  end
end
