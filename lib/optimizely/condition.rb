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
    EXACT = 'exact'
    EXISTS = 'exists'
    GREATER_THAN = 'gt'
    LESS_THAN = 'lt'
    SUBSTRING = 'substring'
  end

  class ConditionEvaluator
    CUSTOM_ATTRIBUTE_CONDITION_TYPE = 'custom_attribute'

    DEFAULT_OPERATOR_TYPES = [
      ConditionalOperatorTypes::AND,
      ConditionalOperatorTypes::OR,
      ConditionalOperatorTypes::NOT
    ].freeze

    EXACT_MATCH_ALLOWED_TYPES = [FalseClass, Numeric, String, TrueClass].freeze

    MATCH_TYPES = [
      ConditionalMatchTypes::EXACT,
      ConditionalMatchTypes::EXISTS,
      ConditionalMatchTypes::GREATER_THAN,
      ConditionalMatchTypes::LESS_THAN,
      ConditionalMatchTypes::SUBSTRING
    ].freeze

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

      return nil unless single_condition.length > 0

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
        first_operator = conditions[0]
        rest_of_conditions = DEFAULT_OPERATOR_TYPES.include?(first_operator) ? conditions[1..-1] : conditions

        case first_operator
        when ConditionalOperatorTypes::AND
          return and_evaluator(rest_of_conditions)
        when ConditionalOperatorTypes::NOT
          return not_evaluator(rest_of_conditions)
        else
          return or_evaluator(rest_of_conditions)
        end
      end

      leaf_condition = conditions

      return nil unless leaf_condition['type'] == CUSTOM_ATTRIBUTE_CONDITION_TYPE

      condition_match = leaf_condition['match']

      return nil if !condition_match.nil? && !MATCH_TYPES.include?(condition_match)

      condition_match = ConditionalMatchTypes::EXACT if condition_match.nil?

      case condition_match
      when ConditionalMatchTypes::EXACT
        return exact_evaluator(leaf_condition)
      when ConditionalMatchTypes::EXISTS
        return exists_evaluator(leaf_condition)
      when ConditionalMatchTypes::GREATER_THAN
        return greater_than_evaluator(leaf_condition)
      when ConditionalMatchTypes::LESS_THAN
        return less_than_evaluator(leaf_condition)
      when ConditionalMatchTypes::SUBSTRING
        return substring_evaluator(leaf_condition)
      end
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

      EXACT_MATCH_ALLOWED_TYPES.any? { |type| value.is_a?(type) }
    end

    def different_types?(condition_type, user_provided_type)
      # Returns false if given types are boolean.
      #         true if condition_type and user_provided_type are of same types.
      #         false otherwise.

      return false if [TrueClass, FalseClass].include?(condition_type) && [TrueClass, FalseClass].include?(user_provided_type)
      condition_type != user_provided_type
    end
  end
end
