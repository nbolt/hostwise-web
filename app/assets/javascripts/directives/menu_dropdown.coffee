app = angular.module('porter').directive('menuDropdown', [-> (scope, element, attrs) ->
  sidebar = element.parents('body').find('#sidebar-container')
  element.on 'click', ->
    sidebar.toggle()
    sidebar.on 'mouseleave', ->
      sidebar.hide()
])
