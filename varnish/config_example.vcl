  # Scope of configuration:
  #   - anonymous users receive cached pages
  #   - logged users interact always directly with Redmine application
  #
  # Note that this configuration has no protection against Denial of Service Attacks, 
  # because malicious attackers can request pages using a not valid Redmine session cookie, 
  # or requesting not existing pages, and all these requests will be sent to Redmine server. 
  # The server will not consider them as valid requests, but in any case the server is stressed with a lot of requests,
  # that are not filtered from the web cache.
  #

  include "/home/zanibonim/lavoro/dry/website/alba/vendor/plugins/redmine_cacheable_pages/varnish/accept-language.vcl";
  #
  # :CUSTOMIZE: specify the correct path
  #
  # Allows caching according user accepted languages.
  # 
  # Use https://github.com/cosimo/varnish-accept-language
  #
  # I generated the accepted languagtes, using the command:
  #
  # > make DEFAULT_LANGUAGE="en" SUPPORTED_LANGUAGES="bg bs ca cs da de el  en-GB en es eu fi fr gl he hr hu id it ja ko lt lv mk mn nl no pl pt-BR pt ro ru sk sl sr sr-YU sv th tr uk vi zh-TW zh"
  #
  # Regenerate it if there are differences.


  # The Redmine server. 
  #
  backend default {
      .host = "127.0.0.1";
      .port = "8085";
      # :CUSTOMIZE: 

      .max_connections = 32;
      # :CUSTOMIZE: change according backend settings
  }

  # Called when Varnish receives a request from a user
  #
  sub vcl_recv {

    # Put inside "X-Varnish-Accept-Language" the preferred language supported from the user,
    # and supported from Redmine.
    #
    C{
      vcl_rewrite_accept_language(sp);
    }C

    if (req.backend.healthy) {
      # If the cached object is inside this grace period, use it for anonymous users, 
      # instead of waiting for the new version of the object.
      #
      # The object will be updated in any case inside the cache, 
      # but the user will receive immediately the cached (but old) version.
      #
      # The major effect of this instruction is reducing the problem of a lot of objects that must be renewed 
      # at the same time, slowing down all anonymous users.
      #
      set req.grace = 30s;
    } else {
      # It is better serving something, than nothing... in case of problems on the backend.
      # 
      set req.grace = 7d;
    }

    if (req.http.x-forwarded-for) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For ", " client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }

    # Only cache GET and HEAD requests
    #
    if (req.request != "GET" && req.request != "HEAD") {
      return (pass);
    }

    # Do not cache HTTP authorized users.
    #
    if (req.http.Authorization) {
      return (pass);
    }

    # This is always static content, so it is safe using the cache
    #
    if (req.url ~ "\.(css|js|jpg|jpeg|gif|ico|png)\??\d*$") {
      unset req.http.Cookie;
      return (lookup);
    }

    # :CUSTOMIZE:
    # _redmine_session is the default Redmine session name. If you changed it, update this value
    #
    if (req.http.Cookie ~ "_redmine_session") {
      # Mantain the cookies because they are probably important.
      #
      # Note: if the user send a redmine session cookie, but he is no anymore logged, then it is detected
      # and all next requests from the user will be anonymous and they will use the cache.
      # Bu up to date only Redmine can manage authentications code, 
      # and so a request with the session/authentication cookie, must be always processed from
      # Redmine the first time.
      #
      return (pass);
    } else {
      # This is a request from an anonymous user, so remove cookies and search it in the cache.
      #
      unset req.http.Cookie;
      return (lookup);
    }
  }

  # Called when receiving a response from the backend (Redmine application).
  #
  sub vcl_fetch {

    if (beresp.http.Vary) {
      # Instead of caching according "Accept-Language", 
      # use the optimized "X-Varnish-Accept-Language" variant,
      # stored on the request.
      #
      set beresp.http.Vary = regsuball(beresp.http.Vary, "[Aa]ccept-[Ll]anguage", "X-Varnish-Accept-Language");
    } 

    # Apply some optimizations to static assets
    #
    if (req.url ~ "\.(css|js|jpg|jpeg|gif|ico|png)\??\d*$") {
      unset beresp.http.Set-Cookie;
      return (deliver);
    } 

    if (beresp.http.Cache-Control ~ "public") {
      # This is a public/cacheable page. 
      #
      # Remove custom cookies from the answer.
      # For example Redmine generates always a session cookie, 
      # also if the user is anonymous and not logged.
      #
      unset beresp.http.Set-Cookie;

      return (deliver);
    } else {
      # The page is private, then it is not cached.
      #
      return (pass);
    }
  }

  # Called before sending the response to the client.
  #
  sub vcl_deliver {
    if (resp.http.Vary) {
      # Send the correct Vary value, with the original request field, and not the optimized "X-Varnish-Accept-Language".
      #
      set resp.http.Vary = regsuball(resp.http.Vary, "[Xx]-[Vv]arnish-[Aa]ccept-[Ll]anguage", "Accept-Language");
    } 

    if (resp.http.Cache-Control ~ "public") {
      # :CUSTOMIZE:
      # _redmine_session is the default Redmine session name. If you changed it, update this value
      #
      if (req.http.Cookie ~ "_redmine_session") {
	# This is a public page, associated to an anonymous user, but the user used a session cookie, 
	# like he were an authenticate user. 
	# Inform the user to remove the cookie, otherwise all his next requestes will be considered as (potentially) 
	# requests from a logged user, and they will be not cached.
	#  
	# TODO: if Redmine sends other cookies, then they are overwritten and not sent, 
	# because "Set-Cookie" Varnish instruction, overwrite all previous cookie related instructions.
	# Update this code when Varnish will manage multiple set-cookie instructions.
	# 
	#
	# :CUSTOMIZE:
	# _redmine_session is the default Redmine session name. If you changed it, update this value
	#
	set resp.http.Set-Cookie = "_redmine_session=; path=/; expires=Thu, 01-Jan-1970 00:00:00 GMT";
      }
    }

    return (deliver);
  }

