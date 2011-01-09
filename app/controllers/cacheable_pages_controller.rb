# TODO mostra HELP del plugin con indicato come cambiare il parametro di configurazione, il setup VCL da fare e altre cose

# TODO dovrei inserire un file di testo dentro al controller e cose del genere e devo imparare come fa Rails a inserire delle pagine semplici e cose del genere

# TODO 

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

