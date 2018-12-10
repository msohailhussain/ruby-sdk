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
module Optimizely
  class CustomAttributeConditionEvaluator
    CUSTOM_ATTRIBUTE_CONDITION_TYPE = 'custom_attribute'

    # Conditional match types
    EXACT_MATCH_TYPE = 'exact'
    EXISTS_MATCH_TYPE = 'exists'
    GREATER_THAN_MATCH_TYPE = 'gt'
    LESS_THAN_MATCH_TYPE = 'lt'
    SUBSTRING_MATCH_TYPE = 'substring'

    EVALUATORS_BY_MATCH_TYPE = {
      EXACT_MATCH_TYPE => :exact_evaluator,
      EXISTS_MATCH_TYPE => :exists_evaluator,
      GREATER_THAN_MATCH_TYPE => :greater_than_evaluator,
      LESS_THAN_MATCH_TYPE => :less_than_evaluator,
      SUBSTRING_MATCH_TYPE => :substring_evaluator
    }.freeze

    FINITE_NUMBER_LIMIT = 1.0e+53

    attr_reader :user_attributes

    def initialize(user_attributes)
      @user_attributes = user_attributes
    end

    def evaluate(leaf_condition)
      # Top level method to evaluate audience conditions.
      #
      # conditions - Nested array of and/or conditions.
      #              Example: ['and', operand_1, ['or', operand_2, operand_3]]
      #
      # Returns boolean if the given user attributes match/don't match the given conditions,
      #         nil if the given conditions can't be evaluated.

      return nil unless leaf_condition['type'] == CUSTOM_ATTRIBUTE_CONDITION_TYPE

      condition_match = leaf_condition['match']

      return nil if !condition_match.nil? && !EVALUATORS_BY_MATCH_TYPE.include?(condition_match)

      condition_match = EXACT_MATCH_TYPE if condition_match.nil?

      send(EVALUATORS_BY_MATCH_TYPE[condition_match], leaf_condition)
    end

    def exact_evaluator(condition)
      # Evaluate the given exact match condition for the given user attributes.
      #
      # Returns boolean true if numbers values matched, i.e 2 is equal to 2.0
      #                 true if the user attribute value is equal (===) to the condition value,
      #                 false if the user attribute value is not equal (!==) to the condition value,
      #                 nil if the condition value or user attribute value has an invalid type,
      #                 or if there is a mismatch between the user attribute type and the condition value type.

      condition_value = condition['value']
      condition_type = condition['value'].class

      user_provided_value = @user_attributes[condition['name']]
      user_provided_type = @user_attributes[condition['name']].class

      if user_provided_value.is_a?(Numeric) && condition_value.is_a?(Numeric)
        return true if condition_value.to_f == user_provided_value.to_f
      end

      return nil if !value_valid_for_exact_conditions?(user_provided_value) ||
                    !value_valid_for_exact_conditions?(condition_value) ||
                    different_types?(condition_type, user_provided_type)

      condition_value == user_provided_value
    end

    def exists_evaluator(condition)
      # Evaluate the given exists match condition for the given user attributes.
      # Returns boolean true if both:
      #                    1) the user attributes have a value for the given condition, and
      #                    2) the user attribute value is neither nil nor undefined
      #                 Returns false otherwise

      return false unless @user_attributes

      !@user_attributes[condition['name']].nil?
    end

    def greater_than_evaluator(condition)
      # Evaluate the given greater than match condition for the given user attributes.
      # Returns boolean true if the user attribute value is greater than the condition value,
      #                 false if the user attribute value is less than or equal to the condition value,
      #                 nil if the condition value isn't a number or the user attribute value isn't a number.

      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil if !finite_number?(user_provided_value) || !finite_number?(condition_value)

      user_provided_value > condition_value
    end

    def less_than_evaluator(condition)
      # Evaluate the given less than match condition for the given user attributes.
      # Returns boolean true if the user attribute value is less than the condition value,
      #                 false if the user attribute value is greater than or equal to the condition value,
      #                 nil if the condition value isn't a number or the user attribute value isn't a number.

      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil if !finite_number?(user_provided_value) || !finite_number?(condition_value)

      user_provided_value < condition_value
    end

    def substring_evaluator(condition)
      # Evaluate the given substring match condition for the given user attributes.
      # Returns boolean true if the condition value is a substring of the user attribute value,
      #                 false if the condition value is not a substring of the user attribute value,
      #                 nil if the condition value isn't a string or the user attribute value isn't a string.

      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil unless user_provided_value.is_a?(String) && condition_value.is_a?(String)

      user_provided_value.include? condition_value
    end

    private

    def value_valid_for_exact_conditions?(value)
      # Returns true if the value is valid for exact conditions. Valid values include
      #  strings, booleans, and numbers that aren't NaN, -Infinity, or Infinity.

      return finite_number?(value) if value.is_a? Numeric

      (value.is_a? FalseClass) || (value.is_a? Integer) || (value.is_a? String) ||
        (value.is_a? TrueClass)
    end

    def different_types?(condition_type, user_provided_type)
      # Returns false if given types are boolean.
      #         true if condition_type and user_provided_type are of same types.
      #         false otherwise.

      return false if [TrueClass, FalseClass].include?(condition_type) && [TrueClass, FalseClass].include?(user_provided_type)

      condition_type != user_provided_type
    end

    def finite_number?(value)
      value.is_a?(Numeric) && value.to_f.finite? && value.to_f <= FINITE_NUMBER_LIMIT
    end
  end
end
