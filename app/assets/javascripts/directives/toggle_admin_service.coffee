app = angular.module('porter').directive('toggleAdminService', ['$http', ($http) -> (scope, element, attrs) ->
  element.on 'change', ->
    if element.is(':checked')
      element.parent().parent().addClass 'active'
      element.parent().parent().children('.name').text 'Cleaning' if attrs.toggleAdminService == 'cleaning'
      $http.post("/jobs/#{scope.job.id}/add_service", {service: attrs.toggleAdminService})
    else
      element.parent().parent().removeClass 'active'
      element.parent().parent().children('.name').text 'Staging' if attrs.toggleAdminService == 'cleaning'
      $http.post("/jobs/#{scope.job.id}/remove_service", {service: attrs.toggleAdminService})
])
