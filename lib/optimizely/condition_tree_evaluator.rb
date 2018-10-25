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
  class ConditionTreeEvaluator
    AND_CONDITION = 'and'
    OR_CONDITION = 'or'
    NOT_CONDITION = 'not'

    CUSTOM_ATTRIBUTE_CONDITION_TYPE = 'custom_attribute'

    DEFAULT_OPERATOR_TYPES = [AND_CONDITION, OR_CONDITION, NOT_CONDITION].freeze

    def evaluate(conditions, leaf_evaluator)
      # Top level method to evaluate audience conditions.
      #
      # conditions - Nested array of and/or conditions.
      #              Example: ['and', operand_1, ['or', operand_2, operand_3]]
      #
      # Returns boolean if the given user attributes match/don't match the given conditions,
      #         nil if the given conditions can't be evaluated.

      if conditions.is_a? Array
        # Operator to apply is not explicit - assume 'or'
        first_operator = DEFAULT_OPERATOR_TYPES.include?(conditions[0]) ? conditions[0] : OR_CONDITION
        rest_of_conditions = DEFAULT_OPERATOR_TYPES.include?(conditions[0]) ? conditions[1..-1] : conditions

        case first_operator
        when AND_CONDITION
          return and_evaluator(rest_of_conditions, leaf_evaluator)
        when NOT_CONDITION
          return not_evaluator(rest_of_conditions, leaf_evaluator)
        else
          return or_evaluator(rest_of_conditions, leaf_evaluator)
        end
      end

      leaf_evaluator.call(conditions)
    end

    def and_evaluator(conditions, leaf_evaluator)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to each entry and the results AND-ed together.
      #
      # conditions - Array of conditions ex: [operand_1, operand_2]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      found_nil = false
      conditions.each do |condition|
        result = evaluate(condition, leaf_evaluator)
        return result if result == false
        found_nil = true if result.nil?
      end

      found_nil ? nil : true
    end

    def or_evaluator(conditions, leaf_evaluator)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to each entry and the results AND-ed together.
      #
      # conditions - Array of conditions ex: [operand_1, operand_2]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      found_nil = false
      conditions.each do |condition|
        result = evaluate(condition, leaf_evaluator)
        return result if result == true
        found_nil = true if result.nil?
      end

      found_nil ? nil : false
    end

    def not_evaluator(single_condition, leaf_evaluator)
      # Evaluates an array of conditions as if the evaluator had been applied
      # to a single entry and NOT was applied to the result.
      #
      # single_condition - Array of a single condition ex: [operand_1]
      #
      # Returns boolean if the user attributes match/don't match the given conditions,
      #         nil if the user attributes and conditions can't be evaluated.

      return nil if single_condition.empty?

      result = evaluate(single_condition[0], leaf_evaluator)
      result.nil? ? nil : !result
    end
  end
end
