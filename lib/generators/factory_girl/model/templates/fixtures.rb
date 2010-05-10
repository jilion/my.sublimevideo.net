Factory.define :<%= singular_name %> do |f|
<% for attribute in attributes -%>
  f.<%= attribute.name %> <%= attribute.default.inspect %>
<% end -%>
end
