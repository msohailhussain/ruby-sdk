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
require 'json'
require 'spec_helper'

describe Optimizely::CustomAttributeConditionEvaluator do
  it 'should return true when the attributes pass the audience conditions and no match type is provided' do
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('browser_type' => 'safari')
    expect(condition_evaluator.evaluate('name' => 'browser_type', 'type' => 'custom_attribute', 'value' => 'safari')).to be true
  end

  it 'should return true when the attributes pass the audience conditions and no match type is provided' do
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('browser_type' => 'firefox')
    expect(condition_evaluator.evaluate('name' => 'browser_type', 'type' => 'custom_attribute', 'value' => 'safari')).to be false
  end

  it 'should evaluate different typed attributes' do
    user_attributes = {
      'browser_type' => 'safari',
      'is_firefox' => true,
      'num_users' => 10,
      'pi_value' => 3.14
    }
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new(user_attributes)

    expect(condition_evaluator.evaluate('name' => 'browser_type', 'type' => 'custom_attribute', 'value' => 'safari')).to be true
    expect(condition_evaluator.evaluate('name' => 'is_firefox', 'type' => 'custom_attribute', 'value' => true)).to be true
    expect(condition_evaluator.evaluate('name' => 'num_users', 'type' => 'custom_attribute', 'value' => 10)).to be true
    expect(condition_evaluator.evaluate('name' => 'pi_value', 'type' => 'custom_attribute', 'value' => 3.14)).to be true
  end

  it 'should return nil when condition has an invalid type property' do
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('weird_condition' => 'bye')
    expect(condition_evaluator.evaluate('match' => 'exact', 'name' => 'weird_condition', 'type' => 'weird', 'value' => 'hi')).to eq(nil)
  end

  it 'should return nil when condition has no type property' do
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('weird_condition' => 'bye')
    expect(condition_evaluator.evaluate('match' => 'exact', 'name' => 'weird_condition', 'value' => 'hi')).to eq(nil)
  end

  it 'should return null when condition has an invalid match property' do
    condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('weird_condition' => 'bye')
    expect(condition_evaluator.evaluate('match' => 'invalid', 'name' => 'weird_condition', 'type' => 'custom_attribute', 'value' => 'bye')).to eq(nil)
  end

  describe 'exists match type' do
    before(:context) do
      @exists_conditions = {'match' => 'exists', 'name' => 'input_value', 'type' => 'custom_attribute'}
    end

    it 'should return false if there is no user-provided value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new({})
      expect(condition_evaluator.evaluate(@exists_conditions)).to be false
    end

    it 'should return false if the user-provided value is nil' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => nil)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be false
    end

    it 'should return true if the user-provided value is a string' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end

    it 'should return true if the user-provided value is a number' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 10)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end

    it 'should return true if the user-provided value is a boolean' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => false)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end
  end

  describe 'exact match type' do
    describe 'with a string condition value' do
      before(:context) do
        @exact_string_conditions = {'match' => 'exact', 'name' => 'location', 'type' => 'custom_attribute', 'value' => 'san francisco'}
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('location' => 'san francisco')
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('location' => 'new york')
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('location' => false)
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('location' => {})
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to eq(nil)
      end
    end

    describe 'with a number condition value' do
      before(:context) do
        @exact_number_conditions = {'match' => 'exact', 'name' => 'sum', 'type' => 'custom_attribute', 'value' => 100}
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('sum' => 100)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('sum' => 101)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('sum' => false)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('sum' => {})
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to eq(nil)
      end
    end

    describe 'with a boolean condition value' do
      before(:context) do
        @exact_boolean_conditions = {'match' => 'exact', 'name' => 'boolean', 'type' => 'custom_attribute', 'value' => false}
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('boolean' => false)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('boolean' => true)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('boolean' => 10)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('boolean' => {})
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to eq(nil)
      end
    end
  end

  describe 'substring match type' do
    before(:context) do
      @substring_conditions = {'match' => 'substring', 'name' => 'text', 'type' => 'custom_attribute', 'value' => 'test message!'}
    end

    it 'should return true if the condition value is a substring of the user-provided value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('text' => 'This is a test message!')
      expect(condition_evaluator.evaluate(@substring_conditions)).to be true
    end

    it 'should return false if the user-provided value is not a substring of the condition value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('text' => 'Not found!')
      expect(condition_evaluator.evaluate(@substring_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a string' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('text' => 10)
      expect(condition_evaluator.evaluate(@substring_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('text' => {})
      expect(condition_evaluator.evaluate(@substring_conditions)).to eq(nil)
    end
  end

  describe 'greater than match type' do
    before(:context) do
      @gt_conditions = {'match' => 'gt', 'name' => 'input_value', 'type' => 'custom_attribute', 'value' => 10}
    end

    it 'should return true if the user-provided value is greater than the condition value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 12)
      expect(condition_evaluator.evaluate(@gt_conditions)).to be true
    end

    it 'should return false if the user-provided value is not greater than the condition value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 8)
      expect(condition_evaluator.evaluate(@gt_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a number' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@gt_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => {})
      expect(condition_evaluator.evaluate(@gt_conditions)).to eq(nil)
    end
  end

  describe 'less than match type' do
    before(:context) do
      @lt_conditions = {'match' => 'lt', 'name' => 'input_value', 'type' => 'custom_attribute', 'value' => 10}
    end

    it 'should return true if the user-provided value is less than the condition value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 8)
      expect(condition_evaluator.evaluate(@lt_conditions)).to be true
    end

    it 'should return false if the user-provided value is not less than the condition value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 12)
      expect(condition_evaluator.evaluate(@lt_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a number' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@lt_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::CustomAttributeConditionEvaluator.new('input_value' => {})
      expect(condition_evaluator.evaluate(@lt_conditions)).to eq(nil)
    end
  end
end
