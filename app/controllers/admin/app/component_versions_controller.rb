class Admin
  module App
    class ComponentVersionsController < Admin::AppController
      respond_to :zip, only: [:show]
      respond_to :html, only: [:destroy]
      respond_to :json

      before_filter :_set_component

      # GET /app/components/:component_id/versions
      def index
        @component_versions = @component.versions.with_deleted
        respond_with @component_versions
      end

      # GET /app/components/:component_id/versions/:id
      def show
        @component_version = @component.versions.with_deleted.where(version: params[:id]).first!
        respond_with @component_version do |format|
          format.zip { redirect_to @component_version.zip.url }
        end
      end

      # POST /app/components/:component_id/versions
      def create
        @component_version = @component.versions.build(_version_params)
        ::App::ComponentVersionManager.new(@component_version).create
        respond_with @component_version, location: [:admin, @component]
      end

      # DELETE /app/components/:component_id/versions/:id
      def destroy
        @component_version = @component.versions.where(version: params[:id]).first!
        ::App::ComponentVersionManager.new(@component_version).destroy
        respond_with @component_version, location: [:admin, @component]
      end

    private

      def _set_component
        @component = ::App::Component.where(token: params[:component_id]).first!
      rescue ActiveRecord::RecordNotFound
        body = { status: 404, error: "Component with token '#{params[:component_id]}' could not be found." }
        render request.format.ref => body, status: 404
      end

      def _version_params
        params.require(:version).permit!
      end
    end
  end
end
