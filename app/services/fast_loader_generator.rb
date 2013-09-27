# services
require 'app/fast_component_version_dependencies_solver'

class FastLoaderGenerator < LoaderGenerator

  private

  def _components_dependencies
    @_components_dependencies ||= App::FastComponentVersionDependenciesSolver.components_dependencies(site, stage)
  end

  def _path
    case stage
    when 'stable'
      "js2/#{token}.js"
    else
      "js2/#{token}-#{stage}.js"
    end
  end

end
