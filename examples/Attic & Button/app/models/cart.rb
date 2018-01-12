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

class Cart < ActiveHash::Base
  
  @@data = []
  
  fields :product_id
  
  def self.create_record(product_id)
    @@data << product_id
  end
  
  def self.get_items
    @@data.group_by{|e| e}.map{|k, v| [k, v.length]}.to_h
  end
  
  def self.delete_all_items
    delete_all
    @@data = []
  end
  
  def self.total_qty
    @@data.length
  end
  
end
