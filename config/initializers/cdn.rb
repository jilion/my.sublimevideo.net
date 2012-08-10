require_dependency 'cdn'
require_dependency 'cdn/voxcast_wrapper'

CDN.wrappers = [CDN::VoxcastWrapper]
