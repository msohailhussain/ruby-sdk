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
require 'spec_helper'
require 'optimizely'
require 'optimizely/logger'
require 'optimizely/helpers/validator'

describe 'ValidatorHelper' do
  let(:spy_logger) { spy('logger') }

  describe '#is_feature_enabled?' do
    before(:example) do
      config_body_JSON = OptimizelySpec::VALID_CONFIG_BODY_JSON
      error_handler = Optimizely::NoOpErrorHandler.new
      logger = Optimizely::NoOpLogger.new
      @config = Optimizely::ProjectConfig.new(config_body_JSON, logger, error_handler)
      @feature_flag = @config.feature_flag_key_map['mutex_group_feature']
    end

    it 'should return true when no experiment ids exist' do
      @feature_flag["experimentIds"] = []
      expect(Optimizely::Helpers::Validator.is_feature_flag_valid?(@config, @feature_flag)).to be(true)
    end

    it 'should return true when only 1 experiment id exists' do
      @feature_flag["experimentIds"] = [@feature_flag["experimentIds"][0]]
      expect(Optimizely::Helpers::Validator.is_feature_flag_valid?(@config, @feature_flag)).to be(true)
    end

    it 'should return true when more than 1 experiment ids exist that belong to the same group' do
      expect(Optimizely::Helpers::Validator.is_feature_flag_valid?(@config, @feature_flag)).to be(true)
    end

    it 'should return false when more than 1 experiment ids exist that belong to different group' do
      @feature_flag["experimentIds"] << '122241'
      expect(Optimizely::Helpers::Validator.is_feature_flag_valid?(@config, @feature_flag)).to be(false)
    end

  end
end
