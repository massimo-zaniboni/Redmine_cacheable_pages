class CacheablePagesController < ApplicationController
  def index
    if defined?(::REDMINE_CACHEABLE_PAGESS_MAX_AGE_IN_MINUTES)
      @cache_max_age_in_minutes = ::REDMINE_CACHEABLE_PAGESS_MAX_AGE_IN_MINUTES
    else
      @cache_max_age_in_minutes = 10
    end
    render(:layout => "admin")
  end
end

