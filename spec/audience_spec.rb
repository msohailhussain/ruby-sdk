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

  it 'should pass conditions when audience conditions exist else audienceIds are passed' do
    user_attributes = {'test_attribute' => 'test_value_1'}
    experiment = @project_instance.config.experiment_key_map['test_experiment']
    experiment['audienceIds'] = ['11154']
    allow(Optimizely::ConditionTreeEvaluator).to receive(:evaluate)

    # Both Audience Ids and Conditions exist
    experiment['audienceConditions'] = ['and', %w[or 3468206642 3988293898], %w[or 3988293899 3468206646 3468206647 3468206644 3468206643]]
    Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                             experiment,
                                             user_attributes)
    expect(Optimizely::ConditionTreeEvaluator).to have_received(:evaluate).with(experiment['audienceConditions'], any_args).once

    # Audience Ids exist but Audience Conditions is nil
    experiment['audienceConditions'] = nil
    Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                             experiment,
                                             user_attributes)
    expect(Optimizely::ConditionTreeEvaluator).to have_received(:evaluate).with(experiment['audienceIds'], any_args).once
  end

  it 'should return false for user_in_experiment? if there are audiences but nil or empty attributes' do
    experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
    allow(Optimizely::CustomAttributeConditionEvaluator).to receive(:new).and_call_original

    # attributes set to empty dict
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    {})).to be false
    # attributes set to nil
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    nil)).to be false
    expect(Optimizely::CustomAttributeConditionEvaluator).to have_received(:new).with({}).twice
  end

  it 'should return true for user_in_experiment? when condition tree evaluator returns true' do
    experiment = @project_instance.config.experiment_key_map['test_experiment']
    user_attributes = {
      'test_attribute' => 'test_value_1'
    }
    allow(Optimizely::ConditionTreeEvaluator).to receive(:evaluate).and_return(true)
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be true
  end

  it 'should return false for user_in_experiment? when condition tree evaluator returns false or nil' do
    experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
    user_attributes = {
      'browser_type' => 'firefox'
    }

    # condition tree evaluator returns nil
    allow(Optimizely::ConditionTreeEvaluator).to receive(:evaluate).and_return(nil)
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be false

    # condition tree evaluator returns false
    allow(Optimizely::ConditionTreeEvaluator).to receive(:evaluate).and_return(false)
    expect(Optimizely::Audience.user_in_experiment?(@project_instance.config,
                                                    experiment,
                                                    user_attributes)).to be false
  end

  # it 'should correctly evaluate audience Ids and calls custom attribute evaluator for leaf nodes' do
  #   experiment = @project_instance.config.experiment_key_map['test_experiment_with_audience']
  #   user_attributes = {
  #     'browser_type' => 'firefox'
  #   }
  #   experiment['audienceIds'] = ['11154', '11159']
  #   experiment['audienceConditions'] = nil
  #
  #   audience_11154 = @project_instance.config.get_audience_from_id('11154')
  #   audience_11159 = @project_instance.config.get_audience_from_id('11159')
  #
  #   customer_attr = Optimizely::CustomAttributeConditionEvaluator.new({})
  #   allow(customer_attr.evaluate(audience_11154['conditions'])).to receive(:send)
  #
  #   Optimizely::Audience.user_in_experiment?(@project_instance.config,experiment,{})
  #
  #   # expect(dbl).to have_received(:one).ordered
  #   # expect(dbl).to have_received(:two).ordered
  #
  #   expect(customer_attr.evaluate(audience_11154['conditions']))
  #     .to have_received(:send).with(:exact_evaluator, audience_11154['conditions']).once
  #
  #
  #
  # end
end
