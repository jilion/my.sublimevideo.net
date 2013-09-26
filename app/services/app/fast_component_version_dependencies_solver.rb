require 'solve'

module App
  class FastComponentVersionDependenciesSolver
    attr_accessor :dependencies

    def self.components_dependencies(site, stage)
      solver = new(site, stage)
      solver.solve
      solver.dependencies
    end

    def initialize(site, stage)
      @site, @stage, @graph = site, stage, Solve::Graph.new

      @components = [::App::Component.app_component]
      @components += _custom_designs_components.select { |c| c.versions_for_stage(@stage).any? }
      @components.each { |component| _add_component(component) }
    end

    def solve
      demands = @components.map { |component| [component.token, '>= 0.0.0-alpha'] }
      @dependencies = Solve.it!(@graph, demands)
      self
    end

    private

    def _custom_designs_components
      @site.designs.reject { |d| %w[classic light flat].include?(d.name) }.map(&:component)
    end

    def _current_app_component_version
      @_current_app_component_version ||= ::App::Component.app_component.versions_for_stage(@stage)
    end

    def _current_component_version(component)
      component.versions.find_by_version!(_current_app_component_version.version)
    end

    def _add_component(component)
      version = _current_component_version(component)
      graph_component = @graph.artifacts(component.token, version.version)
    end

  end
end
