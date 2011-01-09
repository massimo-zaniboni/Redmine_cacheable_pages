require 'redmine'

Redmine::Plugin.register :redmine_cacheable_pages do
  name 'Redmine Cacheable Pages plugin'
  author 'Massimo Zaniboni <massimo.zaniboni@gmail.com>'
  description 'Pages accessed from not logged users can be safely cached from a web proxy.'
  version '0.0.1'

  menu :admin_menu, :cacheable_pages, { :controller => 'cacheable_pages', :action => 'index' }, :caption => "Cacheable pages"
end

require_dependency 'redmine_cacheable_pages/hooks/cacheable_pages_hooks'


