$('#Headerlogin .form-wrap').html "<%= escape_javascript render(:partial => 'form') %>"
$('form#login-form').attr('data-remote', true);
$("#ErrorMessage").html ""
$('#exampleModal').modal('show');