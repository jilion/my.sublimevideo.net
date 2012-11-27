require_dependency 'service/app/component_version'

class Admin
  module App
    class ComponentVersionsController < Admin::AppController
      respond_to :zip, only: [:show]
      respond_to :html, only: [:destroy]
      respond_to :json

      before_filter :find_component

      # GET /app/components/:component_id/versions
      def index
        @component_versions = @component.versions
        respond_with @component_versions
      end

      # GET /app/components/:component_id/versions/:id
      def show
        @component_version = @component.versions.find_by_version!(params[:id])
        respond_with @component_version do |format|
          format.zip { redirect_to @component_version.zip.url }
        end
      end

      # POST /app/components/:component_id/versions
      def create
        @component_version = @component.versions.build(params[:version], as: :admin)
        Service::App::ComponentVersion.new(@component_version).create
        respond_with @component_version, location: [:admin, @component]
      end

      # DELETE /app/components/:component_id/versions/:id
      def destroy
        @component_version = @component.versions.find_by_version!(params[:id])
        Service::App::ComponentVersion.new(@component_version).destroy
        respond_with @component_version, location: [:admin, @component]
      end

    private

      def find_component
        @component = ::App::Component.find_by_token!(params[:component_id])
      rescue ActiveRecord::RecordNotFound
        body = { status: 404, error: "Component with token '#{params[:component_id]}' could not be found." }
        render request.format.ref => body, status: 404
      end

    end
  end
end
