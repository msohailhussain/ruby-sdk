<% if @error %>
  $("#ErrorMessage").html "<div class=\"alert alert-danger\" role=\"alert\">\n" +"<%= @error %>"+"</div>"
<% else %>
  window.location.href = '/demo/<%= session[:current_user][:user_id] %>/shop'
<% end %>