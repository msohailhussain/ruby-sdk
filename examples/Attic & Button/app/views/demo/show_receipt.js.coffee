$('#receiptBody').html "<%= escape_javascript render(:partial => 'cart', locals: { cart: @cart, discount_percentage: @discount_percentage, receipt: true}) %>"
$('#receiptModal').modal('show');