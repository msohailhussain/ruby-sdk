# frozen_string_literal: true

#
#    Copyright 2016-2018, Optimizely and contributors
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
require 'json'

module Optimizely
  class ConditionalOperatorTypes
    AND = 'and'
    OR = 'or'
    NOT = 'not'
  end

  class ConditionalMatchTypes
    EXACT_MATCH_TYPE = 'exact'
    EXISTS_MATCH_TYPE = 'exists'
    GREATER_THAN_MATCH_TYPE = 'gt'
    LESS_THAN_MATCH_TYPE = 'lt'
    SUBSTRING_MATCH_TYPE = 'substring'
  end

  class ConditionEvaluator
    CUSTOM_ATTRIBUTE_CONDITION_TYPE = 'custom_attribute'

    EVALUATORS_BY_OPERATOR_TYPE = {
      ConditionalOperatorTypes::AND => :and_evaluator,
      ConditionalOperatorTypes::OR => :or_evaluator,
      ConditionalOperatorTypes::NOT => :not_evaluator
    }.freeze

    EXACT_MATCH_ALLOWED_TYPES = [FalseClass, Numeric, String, TrueClass].freeze

    EVALUATORS_BY_MATCH_TYPE = {
      ConditionalMatchTypes::EXACT_MATCH_TYPE => :exact_evaluator,
      ConditionalMatchTypes::EXISTS_MATCH_TYPE => :exists_evaluator,
      ConditionalMatchTypes::GREATER_THAN_MATCH_TYPE => :greater_than_evaluator,
      ConditionalMatchTypes::LESS_THAN_MATCH_TYPE => :less_than_evaluator,
      ConditionalMatchTypes::SUBSTRING_MATCH_TYPE => :substring_evaluator
    }.freeze

    attr_reader :user_attributes

    def initialize(user_attributes)
      @user_attributes = user_attributes
    end

    def and_evaluator(conditions)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to each entry and the results AND-ed together.
      #
      # conditions - Array of conditions ex: [operand_1, operand_2]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      found_nil = false
      conditions.each do |condition|
        result = evaluate(condition)
        return result if result == false
        found_nil = true if result.nil?
      end

      found_nil ? nil : true
    end

    def or_evaluator(conditions)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to each entry and the results AND-ed together.
      #
      # conditions - Array of conditions ex: [operand_1, operand_2]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      found_nil = false
      conditions.each do |condition|
        result = evaluate(condition)
        return result if result == true
        found_nil = true if result.nil?
      end

      found_nil ? nil : false
    end

    def not_evaluator(single_condition)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to a single entry and NOT was applied to the result.
      #
      # single_condition - Array of a single condition ex: [operand_1]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      return nil if single_condition.empty?

      result = evaluate(single_condition[0])
      result.nil? ? nil : !result
    end

    def evaluator(condition_array)
      # Method to compare single audience condition against provided user data i.e. attributes.
      #
      # condition_array - Array consisting of condition key and corresponding value.
      #
      # Returns boolean indicating the result of comparing the condition value against the user attributes.

      condition_array[1] == @user_attributes[condition_array[0]]
    end

    def evaluate(conditions)
      # Top level method to evaluate audience conditions.
      #
      # conditions - Nested array of and/or conditions.
      #              Example: ['and', operand_1, ['or', operand_2, operand_3]]
      #
      # Returns boolean if the given user attributes match/don't match the given conditions,
      #         nil if the given conditions can't be evaluated.

      if conditions.is_a? Array
        # Operator to apply is not explicit - assume 'or'
        first_operator = EVALUATORS_BY_OPERATOR_TYPE.include?(conditions[0]) ? conditions[0] : ConditionalOperatorTypes::OR
        rest_of_conditions = EVALUATORS_BY_OPERATOR_TYPE.include?(conditions[0]) ? conditions[1..-1] : conditions

        return send(EVALUATORS_BY_OPERATOR_TYPE[first_operator], rest_of_conditions)
      end

      leaf_condition = conditions

      return nil unless leaf_condition['type'] == CUSTOM_ATTRIBUTE_CONDITION_TYPE

      condition_match = leaf_condition['match']

      return nil if !condition_match.nil? && !EVALUATORS_BY_MATCH_TYPE.include?(condition_match)

      condition_match = ConditionalMatchTypes::EXACT_MATCH_TYPE if condition_match.nil?

      send(EVALUATORS_BY_MATCH_TYPE[condition_match], leaf_condition)
    end

    def exact_evaluator(condition)
      # Evaluate the given exact match condition for the given user attributes.
      #
      # Returns boolean true if the user attribute value is equal (===) to the condition value,
      #                 false if the user attribute value is not equal (!==) to the condition value,
      #                 nil if the condition value or user attribute value has an invalid type,
      #                 or if there is a mismatch between the user attribute type and the condition value type.

      condition_value = condition['value']
      condition_type = condition['value'].class

      user_provided_value = @user_attributes[condition['name']]
      user_provided_type = @user_attributes[condition['name']].class

      return nil if !value_valid_for_exact_conditions?(user_provided_value) ||
                    !value_valid_for_exact_conditions?(condition_value) ||
                    different_types?(condition_type, user_provided_type)

      condition_value == user_provided_value
    end

    def exists_evaluator(condition)
      # Evaluate the given exists match condition for the given user attributes.
      # Returns boolean true if both:
      #                    1) the user attributes have a value for the given condition, and
      #                    2) the user attribute value is neither null nor undefined
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

      return nil unless user_provided_value.is_a?(Numeric) && condition_value.is_a?(Numeric)

      return nil if infinite_number?(user_provided_value) || infinite_number?(condition_value)

      user_provided_value > condition_value
    end

    def less_than_evaluator(condition)
      # Evaluate the given less than match condition for the given user attributes.
      # Returns boolean true if the user attribute value is less than the condition value,
      #                 false if the user attribute value is greater than or equal to the condition value,
      #                 nil if the condition value isn't a number or the user attribute value isn't a number.

      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil unless user_provided_value.is_a?(Numeric) && condition_value.is_a?(Numeric)

      return nil if infinite_number?(user_provided_value) || infinite_number?(condition_value)

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

      return value.finite? if value.is_a? Float

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

    def infinite_number?(value)
      value.is_a?(Float) && !value.finite?
    end
  end
end
