class Admin
  module App
    class ComponentsController < Admin::AppController
      respond_to :html, only: [:show, :update]
      respond_to :json

      # GET /app/components
      def index
        @components = ::App::Component.order(created_at: :desc)
        respond_with @components
      end

      # GET /app/components/:id (token)
      def show
        @components = ::App::Component.order(:name)
        @component  = ::App::Component.where(token: params[:id]).first!
        respond_with @component
      end

      # POST /app/components
      def create
        @component = ::App::Component.new(_component_params)
        @component.save
        respond_with @component, location: [:admin, @component]
      end

      # PUT /app/components/:id (token)
      def update
        @component = ::App::Component.where(token: params[:id]).first!
        App::Component.update(_component_params)
        respond_with @component, location: [:admin, @component]
      end

      # DELETE /app/components/:id (token)
      def destroy
        @component = ::App::Component.where(token: params[:id]).first!
        @component.destroy
        respond_with @component, location: [:admin, :app, :components]
      end

    private

      def _component_params
        params.require(:component).permit!
      end
    end
  end
end
