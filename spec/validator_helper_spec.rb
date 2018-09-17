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
require 'spec_helper'
require 'optimizely'
require 'optimizely/logger'
require 'optimizely/helpers/validator'

describe 'ValidatorHelper' do
  let(:spy_logger) { spy('logger') }

  describe '.attributes_valid?' do
    it 'should return true when valid attributes are passed' do
      expect(Optimizely::Helpers::Validator.attributes_valid?({})).to eq(true)
      expect(
        Optimizely::Helpers::Validator.attributes_valid?(
          boolean: false,
          double: 5.5,
          integer: 5,
          string: 'value'
        )
      ).to eq(true)
    end

    it 'should return false when invalid attributes are passed' do
      expect(Optimizely::Helpers::Validator.attributes_valid?('key: value')).to eq(false)
      expect(Optimizely::Helpers::Validator.attributes_valid?(%w[key value])).to eq(false)
      expect(Optimizely::Helpers::Validator.attributes_valid?(42)).to eq(false)
      expect(Optimizely::Helpers::Validator.attributes_valid?([])).to eq(false)
      expect(Optimizely::Helpers::Validator.attributes_valid?(false)).to eq(false)
    end
  end

  describe '.attribute_value_type_valid?' do
    it 'should return true when valid type attribute value is passed' do
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?('value')).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(5)).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(5.5)).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(false)).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(true)).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?('')).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(0)).to eq(true)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(0.0)).to eq(true)
    end

    it 'should return false when invalid type attribute value is passed' do
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?({})).to eq(false)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?([])).to eq(false)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(nil)).to eq(false)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(key: 'value')).to eq(false)
      expect(Optimizely::Helpers::Validator.attribute_value_type_valid?(%w[key value])).to eq(false)
    end
  end

  describe '.inputs_valid?' do
    it 'should return false when invalid inputs are passed' do
      expect(Optimizely::Helpers::Validator.inputs_valid?({})).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?([])).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?(2)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?(2.0)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?('2.0')).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?('')).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?(true)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?(false)).to eq(false)
    end

    it 'should log and return false when non string value inputs are passed' do
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: nil}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: ''}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: []}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: {}}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: 2}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: 2.0}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: true}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: false}, spy_logger, Logger::ERROR)).to eq(false)
      expect(spy_logger).to have_received(:log).with(Logger::ERROR, 'User ID is invalid').exactly(8).times
    end

    it 'should log and return false when multiple non string value inputs are passed' do
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: '', experiment_key: true}, spy_logger, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: [], variation_key: 2.0}, spy_logger, Logger::ERROR)).to eq(false)
      expect(spy_logger).to have_received(:log).twice.with(Logger::ERROR, 'User ID is invalid')
      expect(spy_logger).to have_received(:log).once.with(Logger::ERROR, 'Experiment key is invalid')
      expect(spy_logger).to have_received(:log).once.with(Logger::ERROR, 'Variation key is invalid')
    end

    it 'should return true when valid input values are passed' do
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: '2'}, spy_logger, Logger::ERROR)).to eq(true)
      expect(Optimizely::Helpers::Validator.inputs_valid?({
                                                            user_id: 'test_user',
                                                            experiment_key: 'test_experiment',
                                                            variation_key: 'test_variation'
                                                          }, spy_logger, Logger::ERROR)).to eq(true)
    end

    it 'should not log when logger or level are nil' do
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: nil}, nil, Logger::ERROR)).to eq(false)
      expect(Optimizely::Helpers::Validator.inputs_valid?({user_id: nil}, spy_logger, nil)).to eq(false)
      expect(spy_logger).not_to have_received(:log).with(Logger::ERROR, 'User ID is invalid')
    end
  end
end
