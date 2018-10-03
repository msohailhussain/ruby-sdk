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
    EXACT = 'exact'.freeze
    EXISTS = 'exists'.freeze
    GREATER_THAN = 'gt'.freeze
    LESS_THAN = 'lt'.freeze
    SUBSTRING = 'substring'.freeze
  end

  class ConditionEvaluator
    CUSTOM_ATTRIBUTE_CONDITION_TYPE = 'custom_attribute'.freeze

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
      # Returns boolean true if all operands evaluate to true.

      conditions.each do |condition|
        result = evaluate(condition)
        return result if (result == false) || result.nil?
      end

      true
    end

    def or_evaluator(conditions)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to each entry and the results AND-ed together.
      #
      # conditions - Array of conditions ex: [operand_1, operand_2]
      #
      # Returns boolean true if any operand evaluates to true.

      conditions.each do |condition|
        result = evaluate(condition)
        return result if (result == true) || result.nil?
      end

      false
    end

    def not_evaluator(single_condition)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to a single entry and NOT was applied to the result.
      #
      # single_condition - Array of a single condition ex: [operand_1]
      #
      # Returns boolean true if the operand evaluates to false.

      return false if single_condition.length != 1

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
      # Returns boolean result of evaluating the conditions evaluated.
      #         nil if the given conditions can't be evaluated.

      if conditions.is_a? Array
        operator_type = conditions[0]
        # Operator to apply is not explicit - assume 'or'
        operator_type = ConditionalOperatorTypes::OR unless DEFAULT_OPERATOR_TYPES.include?(operator_type)

        case operator_type
        when ConditionalOperatorTypes::AND
          return and_evaluator(conditions[1..-1])
        when ConditionalOperatorTypes::OR
          return or_evaluator(conditions[1..-1])
        when ConditionalOperatorTypes::NOT
          return not_evaluator(conditions[1..-1])
        end
      end

      return nil unless (conditions['type'] == CUSTOM_ATTRIBUTE_CONDITION_TYPE) &&
          MATCH_TYPES.include?(conditions['match'])

      match_type = conditions['match']

      match_type = ConditionalMatchTypes::EXACT unless MATCH_TYPES.include?(match_type)

      case match_type
      when ConditionalMatchTypes::EXACT
        return exact_evaluator(conditions)
      when ConditionalMatchTypes::EXISTS
        return exists_evaluator(conditions)
      when ConditionalMatchTypes::GREATER_THAN
        return greater_than_evaluator(conditions)
      when ConditionalMatchTypes::LESS_THAN
        return less_than_evaluator(conditions)
      when ConditionalMatchTypes::SUBSTRING
        return substring_evaluator(conditions)
      end
    end

    def exact_evaluator(condition)
      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]
      return nil unless EXACT_MATCH_ALLOWED_TYPES.any? do |type|
        condition_value.is_a?(type) && user_provided_value.is_a?(type)
      end

      return nil unless condition_value.class == user_provided_value.class

      return condition_value === user_provided_value
    end

    def exists_evaluator(condition)
      return !@user_attributes[condition['name']].nil?
    end

    def greater_than_evaluator(condition)
      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil unless (user_provided_value.is_a?(Numeric)) && condition_value.is_a?(Numeric)

      return  user_provided_value > condition_value
    end

    def less_than_evaluator(condition)
      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil unless (user_provided_value.is_a?(Numeric)) && condition_value.is_a?(Numeric)

      return  user_provided_value < condition_value
    end

    def substring_evaluator(condition)
      condition_value = condition['value']
      user_provided_value = @user_attributes[condition['name']]

      return nil unless (user_provided_value.is_a?(String)) && condition_value.is_a?(String)

      return  user_provided_value.include? condition_value
    end

    private

    def audience_condition_deserializer(condition)
      # Deserializer defining how hashes need to be decoded for audience conditions.
      #
      # condition - Hash representing one audience condition.
      #
      # Returns array consisting of condition key and corresponding value.

      [condition['name'], condition['value']]
    end
  end
end
