class App::ComponentVersionDependenciesManager < Struct.new(:site, :mode)
  delegate :components, :name, to: :site, prefix: true

  def self.components_dependencies(site, mode)
    new(site, mode).components_dependencies
  end

  def initialize(*args)
    super
    # puts site_components.inspect
    @components = [App::Component.app_component]
    @components += site_components
  end

  def components_dependencies
    dependencies = {}
    # puts @components.inspect
    @components.each do |component|
      # puts component.inspect
      # puts component.versions
      # puts component.versions.inspect
      version = component.versions.max
      dependencies[component.token] = version.version
    end
    dependencies
  end

end
