# frozen_string_literal: true

#
#    Copyright 2016-2017, Optimizely and contributors
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

describe Optimizely::Audience do
  before(:context) do
    @config_body = OptimizelySpec::VALID_CONFIG_BODY
    @config_body_json = OptimizelySpec::VALID_CONFIG_BODY_JSON
  end

  before(:example) do
    @project_instance = Optimizely::Project.new(@config_body_json)
  end

  it 'should return true for user_in_experiment? when experiment is using no audience' do
    user_attributes = {}
    # Both Audience Ids and Conditions are Empty
		experiment = @project_instance.config.experiment_key_map['test_experiment']
    experiment['audienceIds'] = []
    experiment['audienceConditions'] = []

		expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true

		# Audience Ids exist but Audience Conditions is Empty
    experiment = @project_instance.config.experiment_key_map['test_experiment']
    experiment['audienceIds'] = ['11154']
    experiment['audienceConditions'] = []

    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true

		# Audience Ids is Empty and  Audience Conditions is nil
    experiment = @project_instance.config.experiment_key_map['test_experiment']
    experiment['audienceIds'] = []
    experiment['audienceConditions'] = nil

    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true
	end
  #
  # it 'should return true when user_in_experiment? evaluates non-empty audience' do
  #   user_attributes = {'test_attribute'=> 'test_value_1'}
  #   experiment = @project_instance.config.experiment_key_map['test_experiment']
  #   experiment['audienceIds'] = ['11154']
  #
  #   # Both Audience Ids and Conditions exist
  #   experiment['audienceConditions'] = ['and', ['or', '3468206642', '3988293898'], ['or', '3988293899','3468206646', '3468206647', '3468206644', '3468206643']]
  # end

  it 'should return true for user_in_experiment? if there are no audiences and there are attributes' do
    experiment = @project_instance.config.experiment_key_map['test_experiment']
    user_attributes = {
      'browser_type' => 'firefox'
    }
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true
  end

  it 'should return false for user_in_experiment? if there are audiences but no attributes' do
    experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    nil)).to be false
  end

  it 'should return true for user_in_experiment? if any one of the audience conditions are met' do
    user_attributes = {
      'browser_type' => 'firefox'
    }

    experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true
  end

  it 'should return false for user_in_experiment? if the audience conditions are not met' do
    user_attributes = {
      'browser_type' => 'chrome'
    }
    experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be false
  end
end
