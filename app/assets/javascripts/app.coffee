AppCtrl = ['$scope', '$http', '$timeout', '$q', ($scope, $http, $timeout, $q) ->

  $scope.user_fetched = $q.defer()

  $scope.$on 'fetch_user', ->
    if window.location.href.indexOf('/activate') > 0
      $http.get(window.location.href + '.json').success (rsp) ->
        $scope.user = rsp if rsp
    else
      $http.get('/user').success (rsp) ->
        if rsp
          $scope.user = rsp.user
          $scope.user.payment_prefs = _($scope.user.payments).filter (payment) -> payment.status_cd == 1 or payment.status_cd == 2
          $scope.user.payment_prefs = _($scope.user.payment_prefs).sortBy (payment) -> payment.id
          $scope.user.payments = _($scope.user.payments).filter (payment) -> payment.status_cd == 1
          if $scope.user.role is 'admin'
            $scope.user_fetched.resolve()
          if $scope.user.role is 'host'
            $scope.user_fetched.resolve()
          if $scope.user.role is 'contractor'
            $scope.user.earnings = $scope.user.earnings.toFixed 2
            $scope.user.unpaid = $scope.user.unpaid.toFixed 2
            if $scope.user.contractor_profile.position_cd == 1
              $scope.user.training_jobs = []
              _($scope.user.training).each (jobs) ->
                training = {}
                training.jobs = _(jobs).reject (job) -> job.distribution
                training.distribution_job = _(jobs).find (job) -> job.occasion_cd == 0
                if training.jobs[0]
                  date = moment(training.jobs[0].booking.date, 'YYYY-MM-DD')
                  training.date = date.format 'ddd, MMM D'
                  training.show = date.diff(moment().startOf('day'), 'days') >= 0
                  training.completed = !(_(training.jobs).reject (job) -> job.status_cd == 3)[0]
                  $scope.user.training_jobs.push training
              $scope.user.training_completed = !(_($scope.user.training_jobs).reject (training) -> training.completed)[0]
              $scope.user_fetched.resolve()
            else
              $http.get('/user/jobs_today').success (rsp) ->
                $scope.user.jobs_today = rsp
                $scope.user.pickup_job = _($scope.user.jobs_today).find (job) -> job.occasion_cd == 0
                $scope.user.dropoff_job = _($scope.user.jobs_today).find (job) -> job.occasion_cd == 1
                $scope.user.standard_jobs = _($scope.user.jobs_today).reject (job) -> job.distribution
                $scope.user_fetched.resolve()

  $scope.$emit 'fetch_user'

  angular.element('body').on 'click', ->
    angular.element('#user .drop-container').css 'max-height', 0 if angular.element('#user .drop-container').css('max-height') != '0px'

]

app = angular.module('porter', ['ngCookies',
                                'ui.mask',
                                'ui.select2',
                                'ui.slider',
                                'ngDialog',
                                'ngTouch',
                                'ngSanitize',
                                'angular-carousel',
                                '720kb.tooltips',
                                'angularFileUpload',
                                'timer',
                                'angularUtils.directives.dirPagination'])
  .controller('app', AppCtrl)
  .config(['$httpProvider', '$compileProvider', ($httpProvider, $compileProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = angular.element('meta[name=csrf-token]').attr 'content'
    $compileProvider.aHrefSanitizationWhitelist /^\s*(https?|ftp|file|sms|tel):|data:image\//
  ]).filter 'reverse', -> (items) -> items.slice().reverse()

angular.element(document).on 'ready page:load', ->
  angular.bootstrap('body', ['porter'])
  analytics.page()
