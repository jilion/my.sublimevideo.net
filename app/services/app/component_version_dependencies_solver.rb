require 'solve'

module App
  class ComponentVersionDependenciesSolver
    attr_accessor :dependencies

    def self.components_dependencies(site, stage)
      solver = new(site, stage)
      solver.solve
      solver.dependencies
    end

    def initialize(site, stage)
      @site, @stage, @graph = site, stage, Solve::Graph.new

      @components = [::App::Component.app_component]
      @components += @site.components
      @components.compact.uniq.each { |component| add_component(component) }
    end

    def solve
      demands = @components.map { |component| [component.token] }
      @dependencies = Solve.it!(@graph, demands)
      self
    end

  private

    def add_component(component)
      component.cached_versions.select { |v| v.stage >= @stage }.each do |version|
        graph_component = @graph.artifacts(component.token, version.version)
        version.dependencies.each do |component_name, identifier|
          dep_component = ::App::Component.find_cached_by_name(component_name)
          if @graph.artifacts.none? { |a| a.name == dep_component.token }
            add_component(dep_component)
          end
          graph_component.depends(dep_component.token, identifier)
        end
      end
    end

  end
end
