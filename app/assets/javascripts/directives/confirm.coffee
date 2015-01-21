app = angular.module('porter').directive('ngConfirmClick', [->
  link: (scope, element, attr) ->
    msg = attr.ngConfirmClick or 'Are you sure?'
    clickAction = attr.confirmedClick
    element.bind 'click', (event) ->
      scope.$eval clickAction  if window.confirm(msg)
])
