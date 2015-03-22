AppCtrl = ['$scope', '$http', '$timeout', '$q', ($scope, $http, $timeout, $q) ->

  $scope.user_fetched = $q.defer()

  $scope.$on 'fetch_user', ->
    if window.location.href.indexOf('/activate') > 0
      $http.get(window.location.href + '.json').success (rsp) ->
        $scope.user = rsp if rsp
    else
      $http.get('/user').success (rsp) ->
        if rsp
          $scope.user = rsp
          $scope.user.payment_prefs = _($scope.user.payments).filter (payment) -> payment.status_cd == 1 or payment.status_cd == 2
          $scope.user.payment_prefs = _($scope.user.payment_prefs).sortBy (payment) -> payment.id
          $scope.user.payments = _($scope.user.payments).filter (payment) -> payment.status_cd == 1
          if $scope.user.role is 'admin'
            $scope.user_fetched.resolve()
          if $scope.user.role is 'host'
            $scope.user.properties = _($scope.user.properties).filter (property) -> property.active
            _($scope.user.properties).each (property) ->
              property.next_service_date = moment(property.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if property.next_service_date
            $scope.user_fetched.resolve()
          if $scope.user.role is 'contractor'
            $scope.user.earnings = $scope.user.earnings.toFixed 2
            $scope.user.unpaid = $scope.user.unpaid.toFixed 2
            _($scope.user.jobs).each (job) -> job.contractor_count = job.contractors.length if job.contractors
            if $scope.user.contractor_profile.position_cd == 1
              training_jobs = _(_($scope.user.jobs).groupBy (job) -> moment(job.date, 'YYYY-MM-DD')).sortBy (v,k) -> moment(k, 'ddd MMM DD YYYY').unix()
              $scope.user.training_jobs = []
              _(training_jobs).each (jobs) ->
                training = {}
                training.jobs = _(jobs).reject (job) -> job.distribution
                training.distribution_job = _(jobs).find (job) -> job.occasion_cd == 0
                training.date = moment(training.jobs[0].booking.date, 'YYYY-MM-DD').format 'ddd, MMM D'
                $scope.user.training_jobs.push training
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
                                'angularFileUpload',
                                'timer',
                                'angularUtils.directives.dirPagination'])
  .controller('app', AppCtrl)
  .config ['$httpProvider', '$compileProvider', ($httpProvider, $compileProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = angular.element('meta[name=csrf-token]').attr 'content'
    $httpProvider.interceptors.push 'spinner_request'
    $compileProvider.aHrefSanitizationWhitelist /^\s*(https?|ftp|file|sms|tel):|data:image\//
  ]

angular.element(document).on 'ready page:load', ->
  angular.bootstrap('body', ['porter'])
  analytics.page()
