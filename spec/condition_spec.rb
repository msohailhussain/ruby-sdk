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
require 'spec_helper'

describe Optimizely::ConditionEvaluator do
  before(:context) do
    @config_body = OptimizelySpec::VALID_CONFIG_BODY
  end

  before(:example) do
    user_attributes = {
      'browser_type' => 'firefox',
      'city' => 'san francisco'
    }
    @condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
  end

  it 'should return true for and_evaluator when all conditions evaluate to true' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'firefox'
      }, {
        'name' => 'city',
        'type' => 'custom_attribute',
        'value' => 'san francisco'
      }
    ]
    expect(@condition_evaluator.and_evaluator(conditions)).to be true
  end

  it 'should return false for and_evaluator when any one condition evaluates to false' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'firefox'
      }, {
        'name' => 'city',
        'type' => 'custom_attribute',
        'value' => 'new york'
      }
    ]
    expect(@condition_evaluator.and_evaluator(conditions)).to be false
  end

  it 'should return true for or_evaluator when any one condition evaluates to true' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'firefox'
      }, {
        'name' => 'city',
        'type' => 'custom_attribute',
        'value' => 'new york'
      }
    ]
    expect(@condition_evaluator.or_evaluator(conditions)).to be true
  end

  it 'should return false for or_evaluator when all conditions evaluate to false' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'chrome'
      }, {
        'name' => 'city',
        'type' => 'custom_attribute',
        'value' => 'new york'
      }
    ]
    expect(@condition_evaluator.or_evaluator(conditions)).to be false
  end

  it 'should return true for not_evaluator when condition evaluates to false' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'chrome'
      }
    ]
    expect(@condition_evaluator.not_evaluator(conditions)).to be true
  end

  it 'should return false for not_evaluator when condition evaluates to true' do
    conditions = [
      {
        'name' => 'browser_type',
        'type' => 'custom_attribute',
        'value' => 'firefox'
      }
    ]
    expect(@condition_evaluator.not_evaluator(conditions)).to be false
  end

  it 'should return nil for not_evaluator when condition array is empty' do
    expect(@condition_evaluator.not_evaluator([])).to be nil
  end

  it 'should return true for evaluate when conditions evaluate to true' do
    condition = @config_body['audiences'][0]['conditions']
    condition = JSON.parse(condition)
    expect(@condition_evaluator.evaluate(condition)).to be true
  end

  it 'should evaluate to false for evaluate when conditions evaluate to false' do
    condition = '["and", ["or", ["or", '\
                '{"name": "browser_type", "type": "custom_attribute", "value": "chrome"}]]]'
    condition = JSON.parse(condition)
    expect(@condition_evaluator.evaluate(condition)).to be false
  end

  it 'should evaluate to true for evaluate when NOT conditions evaluate to true' do
    condition = '["not", {"name": "browser_type", "type": "custom_attribute", "value": "chrome"}]'
    condition = JSON.parse(condition)
    expect(@condition_evaluator.evaluate(condition)).to be true
  end

  it 'should return nil when condition has an invalid type property' do
    condition = '["and", {"match": "exact", "name": "weird_condition", "type": "weird", "value": "test"}]'
    condition = JSON.parse(condition)
    expect(@condition_evaluator.evaluate(condition)).to eq(nil)
  end

  it 'should return nil when condition has an invalid match property' do
    condition = '["and", {"match": "weird", "name": "browser_type", "type": "custom_attribute", "chrome": "test"}]'
    condition = JSON.parse(condition)
    expect(@condition_evaluator.evaluate(condition)).to eq(nil)
  end

  describe 'nil handling' do
    before(:context) do
      @exact_browser_condition = {'name' => 'browser_type', 'match' => 'exact', 'type' => 'custom_attribute', 'value' => 'firefox'}
      @exact_device_condition =  {'name' => 'device', 'match' => 'exact', 'type' => 'custom_attribute', 'value' => 'iphone'}
      @exact_location_condition = {'name' => 'location', 'match' => 'exact', 'type' => 'custom_attribute', 'value' => 'san francisco'}
    end
    describe 'and evaluation' do
      it 'should return nil when all operands evaluate to nil' do
        user_attributes = {
          'browser_type' => 4.5,
          'location' => false
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['and', @exact_browser_condition, @exact_location_condition])).to eq(nil)
      end

      it 'should return nil when operands evaluate to trues and nils' do
        user_attributes = {
          'browser_type' => 'firefox',
          'location' => false
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['and', @exact_browser_condition, @exact_location_condition])).to eq(nil)
      end

      it 'should return false when operands evaluate to falses and nils' do
        user_attributes = {
          'browser_type' => 'chrome',
          'location' => false
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['and', @exact_browser_condition, @exact_location_condition])).to be false
      end

      it 'should return false when operands evaluate to trues, falses, and nils' do
        user_attributes = {
          'browser_type' => 'firefox',
          'device' => false,
          'location' => 'NY'
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['and', @exact_browser_condition, @exact_device_condition, @exact_location_condition])).to be false
      end
    end

    describe 'or evaluation' do
      it 'should return nil when all operands evaluate to nil' do
        user_attributes = {
          'browser_type' => 4.5,
          'location' => false
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['or', @exact_browser_condition, @exact_location_condition])).to eq(nil)
      end

      it 'should return true when operands evaluate to trues and nils' do
        user_attributes = {
          'browser_type' => false,
          'location' => 'san francisco'
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['or', @exact_browser_condition, @exact_location_condition])).to be true
      end

      it 'should return nil when operands evaluate to falses and nils' do
        user_attributes = {
          'browser_type' => 'chrome',
          'location' => false
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['or', @exact_browser_condition, @exact_location_condition])).to eq(nil)
      end

      it 'should return true when operands evaluate to trues, falses, and nils' do
        user_attributes = {
          'browser_type' => 'chrome',
          'device' => false,
          'location' => 'san francisco'
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['or', @exact_browser_condition, @exact_device_condition, @exact_location_condition])).to be true
      end
    end

    describe 'not evaluation' do
      it 'should return nil when operand evaluates to nil' do
        user_attributes = {
          'browser_type' => 4.5
        }
        condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
        expect(condition_evaluator.evaluate(['not', @exact_browser_condition])).to eq(nil)
      end
    end
  end

  describe 'implicit operator' do
    it 'should behave like an "or" operator when the first item in the array is not a recognized operator' do
      user_attributes = {
        'browser_type' => 'firefox',
        'device' => 'android'
      }
      condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
      expect(condition_evaluator.evaluate([
                                            {'name' => 'browser_type', 'type' => 'custom_attribute', 'value' => 'firefox'},
                                            {'name' => 'device', 'type' => 'custom_attribute', 'value' => 'iphone'}
                                          ])).to be true

      user_attributes = {
        'browser_type' => 'chrome',
        'device' => 'android'
      }
      condition_evaluator = Optimizely::ConditionEvaluator.new(user_attributes)
      expect(condition_evaluator.evaluate([
                                            {'name' => 'browser_type', 'type' => 'custom_attribute', 'value' => 'firefox'},
                                            {'name' => 'device', 'type' => 'custom_attribute', 'value' => 'iphone'}
                                          ])).to be false
    end
  end

  describe 'exists match type' do
    before(:context) do
      @exists_conditions = ['and', {'match' => 'exists', 'name' => 'input_value', 'type' => 'custom_attribute'}]
    end

    it 'should return false if there is no user-provided value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new({})
      expect(condition_evaluator.evaluate(@exists_conditions)).to be false
    end

    it 'should return false if the user-provided value is nil' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => nil)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be false
    end

    it 'should return true if the user-provided value is a string' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end

    it 'should return true if the user-provided value is a number' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 10)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end

    it 'should return true if the user-provided value is a boolean' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => false)
      expect(condition_evaluator.evaluate(@exists_conditions)).to be true
    end
  end

  describe 'exact match type' do
    describe 'with a string condition value' do
      before(:context) do
        @exact_string_conditions = ['and', {'match' => 'exact', 'name' => 'location', 'type' => 'custom_attribute', 'value' => 'san francisco'}]
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('location' => 'san francisco')
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('location' => 'new york')
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('location' => false)
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('location' => {})
        expect(condition_evaluator.evaluate(@exact_string_conditions)).to eq(nil)
      end
    end

    describe 'with a number condition value' do
      before(:context) do
        @exact_number_conditions = ['and', {'match' => 'exact', 'name' => 'sum', 'type' => 'custom_attribute', 'value' => 100}]
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('sum' => 100)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('sum' => 101)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('sum' => false)
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('sum' => {})
        expect(condition_evaluator.evaluate(@exact_number_conditions)).to eq(nil)
      end
    end

    describe 'with a boolean condition value' do
      before(:context) do
        @exact_boolean_conditions = ['and', {'match' => 'exact', 'name' => 'boolean', 'type' => 'custom_attribute', 'value' => false}]
      end

      it 'should return true if the user-provided value is equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('boolean' => false)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to be true
      end

      it 'should return false if the user-provided value is not equal to the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('boolean' => true)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to be false
      end

      it 'should return nil if the user-provided value is of a different type than the condition value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('boolean' => 10)
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to eq(nil)
      end

      it 'should return nil if there is no user-provided value' do
        condition_evaluator = Optimizely::ConditionEvaluator.new('boolean' => {})
        expect(condition_evaluator.evaluate(@exact_boolean_conditions)).to eq(nil)
      end
    end
  end

  describe 'substring match type' do
    before(:context) do
      @substring_conditions = ['and', {'match' => 'substring', 'name' => 'text', 'type' => 'custom_attribute', 'value' => 'test message!'}]
    end

    it 'should return true if the condition value is a substring of the user-provided value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('text' => 'This is a test message!')
      expect(condition_evaluator.evaluate(@substring_conditions)).to be true
    end

    it 'should return false if the user-provided value is not a substring of the condition value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('text' => 'Not found!')
      expect(condition_evaluator.evaluate(@substring_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a string' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('text' => 10)
      expect(condition_evaluator.evaluate(@substring_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('text' => {})
      expect(condition_evaluator.evaluate(@substring_conditions)).to eq(nil)
    end
  end

  describe 'greater than match type' do
    before(:context) do
      @gt_conditions = ['and', {'match' => 'gt', 'name' => 'input_value', 'type' => 'custom_attribute', 'value' => 10}]
    end

    it 'should return true if the user-provided value is greater than the condition value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 12)
      expect(condition_evaluator.evaluate(@gt_conditions)).to be true
    end

    it 'should return false if the user-provided value is not greater than the condition value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 8)
      expect(condition_evaluator.evaluate(@gt_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a number' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@gt_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => {})
      expect(condition_evaluator.evaluate(@gt_conditions)).to eq(nil)
    end
  end

  describe 'less than match type' do
    before(:context) do
      @lt_conditions = ['and', {'match' => 'lt', 'name' => 'input_value', 'type' => 'custom_attribute', 'value' => 10}]
    end

    it 'should return true if the user-provided value is less than the condition value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 8)
      expect(condition_evaluator.evaluate(@lt_conditions)).to be true
    end

    it 'should return false if the user-provided value is not less than the condition value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 12)
      expect(condition_evaluator.evaluate(@lt_conditions)).to be false
    end

    it 'should return nil if the user-provided value is not a number' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => 'test')
      expect(condition_evaluator.evaluate(@lt_conditions)).to eq(nil)
    end

    it 'should return nil if there is no user-provided value' do
      condition_evaluator = Optimizely::ConditionEvaluator.new('input_value' => {})
      expect(condition_evaluator.evaluate(@lt_conditions)).to eq(nil)
    end
  end
end
