app = angular.module('porter').directive('imageOnLoad', [-> (scope, element, attrs) ->
  element.bind 'load', ->
    scope.$apply attrs.imageonload
])
