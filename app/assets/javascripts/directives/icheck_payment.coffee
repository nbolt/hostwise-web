app = angular.module('porter').directive('icheckPayment', [-> (scope, element, attrs) ->
  element.iCheck
    checkboxClass: "icheckbox_square-#{attrs.icheckPayment}"
    radioClass: "iradio_square-#{attrs.icheckPayment}"

  element.on 'ifChecked', ->
    scope.select_payment element.val()
])