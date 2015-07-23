module Incident
  class LegacySitesController < ApplicationController
    include ApplicationHelper
    before_filter :check_user

    def index
    	@sites = Legacy::LegacySite.paginate(:page => params[:page])
    end

    def map
        @legacy_event_id = params[:id]
    end

    def form
    end
  end
end