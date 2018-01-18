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

module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type
    when 'success'
      'alert-success'   # Green
    when 'error'
      'alert-danger'    # Red
    when 'alert'
      'alert-warning'   # Yellow
    when 'notice'
      'alert-info'      # Blue
    else
      flash_type.to_s
    end
  end

  def assign_active_class(path)
    current_page?(path) ? 'active' : ''
  end

  def generate_json_view(json)
    JSON.pretty_generate JSON.parse(json)
  end

  def active_class(visitor_id)
    return 'active' if visitor_id == session[:visitor_id]
  end

  def calculate_percentage(number, percent)
    (number.to_f * (percent / 100.0)).to_s(:rounded, precision: 2)
  end

  def cart_total(sum, percent)
    (sum.to_f - calculate_percentage(sum, percent).to_f).to_s(:rounded, precision: 2)
  end

  def get_first_name(current_user)
    current_user['email'].present? ? (current_user['name'].split('.')[0]).capitalize : ''
  end

  def get_last_name(current_user)
    current_user['email'].present? ? (current_user['name'].split('.')[1]).try(:capitalize) : ''
  end

  def full_name(current_user)
    if current_user['name']
      get_first_name(current_user).to_s + ' ' + get_last_name(current_user).to_s
    else
      'Guest User'
    end
  end
end
