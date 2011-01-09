module RedmineCacheablePages
  mattr_accessor :cache_max_age_in_minutes
  self.cache_max_age_in_minutes = 5

  class RedmineCacheabkePagesHooks < Redmine::Hook::ViewListener

    def application_controller_before_sending_response(context = { })
      user = context[:user]
      request = context[:request]
      headers = context[:headers]
      logger = context[:logger]

      is_not_cacheable = (user.logged? || (! request.get?) || request.path == '/login' || request.path == '/account/register')

      if is_not_cacheable
        headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
      else
        cache_refresh = 2 * 60 # TODO use the correct value
        headers['Cache-Control'] = 'public, max-age=' + cache_refresh.to_s
        headers.delete('Expires')
        headers['Vary'] = 'Accept-Language, Cookie'
      end
    end
  end
end
