app = angular.module('porter').directive('newPropertyPhoto', [-> (scope, element, attrs) ->
  element.on 'change', ->
    f = element[0].files[0]
    r = new FileReader()
    r.onloadend = (e) -> angular.element('#preview').attr('src', e.target.result)
    r.readAsDataURL(f)
])