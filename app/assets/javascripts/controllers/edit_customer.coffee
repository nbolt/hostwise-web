EditCustomerCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  url = window.location.href.split('/')
  $scope.id = url[url.length-2]

  $http.get(window.location.href + '.json').success (rsp) ->
    $scope.host = rsp

  $scope.update_account = ->
    $http.put("/hosts/#{$scope.id}/update", {
      host: $scope.host
    }).success (rsp) ->
      if rsp.success
        window.location = window.location.href
      else
        flash 'failure', rsp.message

  $scope.open_deactivation = ->
    $scope.current_name = "#{$scope.host.first_name}'s"
    ngDialog.open template: 'account-deactivation-modal', controller: 'edit-customer', className: 'account', scope: $scope

  $scope.open_reactivation = ->
    $scope.current_name = "#{$scope.host.first_name}'s"
    ngDialog.open template: 'account-reactivation-modal', controller: 'edit-customer', className: 'account', scope: $scope

  $scope.cancel_deactivation = ->
    ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    $http.post("/hosts/#{$scope.id}/deactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  $scope.confirm_reactivation = ->
    $http.post("/hosts/#{$scope.id}/reactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  flash = (type, msg) ->
    el = angular.element('form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    scroll 0
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

]

app = angular.module('porter').controller('edit-customer', EditCustomerCtrl)
