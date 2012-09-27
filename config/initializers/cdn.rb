require_dependency 'cdn'
require_dependency 'cdn/voxcast_wrapper'
require_dependency 'cdn/edgecast_wrapper'

CDN.wrappers = [
  CDN::EdgeCastWrapper,
  CDN::VoxcastWrapper
]
