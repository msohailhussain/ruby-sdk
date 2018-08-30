module UserProfileServices
  class BaseService
    attr_accessor :user_profiles

    def initialize(user_profiles = nil)
      @user_profiles = {}
      if user_profiles
        user_profiles.each do |profile|
          profile[:user_id] = profile['user_id']
          profile.delete('user_id')
          profile[:experiment_bucket_map] = profile['experiment_bucket_map']
          profile.delete('experiment_bucket_map')
          profile[:experiment_bucket_map].each_value do |decision|
            decision[:variation_id] = decision['variation_id']
            decision.delete('variation_id')
          end

          @user_profiles[profile[:user_id]] = profile
        end
      end
    end
  end

  class NormalService < BaseService
    def lookup(user_id)
      return @user_profiles[user_id]
    end

    def save(user_profile)
      user_id = user_profile[:user_id]
      @user_profiles[user_id] = user_profile
    end
  end

  class LookupErrorService < NormalService
    def lookup(user_id)
      throw :LookupError
    end
  end

  class SaveErrorService < NormalService
    def save(user_profile)
      throw :SaveError
    end
  end
end
