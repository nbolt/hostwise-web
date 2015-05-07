JobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', '$q', '$upload', 'spinner', 'ngDialog', ($scope, $http, $timeout, $interval, $window, $q, $upload, spinner, ngDialog) ->

  $scope.jobQ = $q.defer()
  $scope.job_status = 'blocked'
  $scope.active_bedroom = 1
  $scope.active_bathroom = 1
  $scope.arrival = true

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.index_in_day = rsp.index_in_day
    $scope.next_job = rsp.next_job.id if rsp.next_job
    $scope.prev_job = rsp.prev_job.id if rsp.prev_job
    $scope.job.cant_access_seconds_left = 1 if $scope.job.cant_access_seconds_left == 0
    $scope.job.booking.property.checklist_bedrooms = $scope.job.booking.property.bedrooms
    $scope.job.booking.property.checklist_bedrooms = 1 if $scope.job.booking.property.bedrooms == 0
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.date_text_2 = moment(rsp.date, 'YYYY-MM-DD').format 'MMMM Do, YYYY'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services = _(rsp.booking.services).filter (s) -> s.extra
    $scope.staging = _($scope.job.standard_services).find (s) -> s.display == 'Staging'
    $scope.vip = $scope.job.state_cd == 1 unless $scope.staging #always show staging if it is a staging and vip job
    $scope.job.hide_details = $scope.job and $scope.job.status_cd == 1 and moment(rsp.date, 'YYYY-MM-DD').diff(moment().startOf('day'), 'days') > 0

    $timeout -> $scope.jobQ.resolve()
    $scope.user_fetched.promise.then ->
      $scope.is_applicant = $scope.user and $scope.user.contractor_profile.position_cd == 1
      $scope.job.contractors = _($scope.job.contractors).reject (user) -> user.id == $scope.user.id
      $scope.job.applicants = _($scope.job.contractors).reject (user) -> user.contractor_profile.position_cd != 1
      $scope.job.mentors = _($scope.job.contractors).reject (user) -> user.contractor_profile.position_cd != 3
      $scope.job.team_members = _($scope.job.contractors).reject (user) -> user.contractor_profile.position_cd == 1

    $http.get($window.location.href + '/status').success (rsp) ->
      $scope.job.status = rsp.status
      $scope.job.blocker = rsp.blocker

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map('map', 'useporter.l02en9o9',
          dragging: false
          touchZoom: false
          scrollWheelZoom: false
          doubleClickZoom: false
          attributionControl: false)
        markers = new L.LayerGroup().addTo(map)
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.job.booking.property.full_address, (err, data) ->
          if data.latlng
            map.setView([data.latlng[0], data.latlng[1]], 14)
            markers.clearLayers() # always clear previous markers
            L.marker([data.latlng[0], data.latlng[1]], {
              icon: L.icon({
                iconUrl: '/images/pin.png',
                iconSize: [28, 49],
              })
            }).addTo markers
    ), 200)

    $scope.user_fetched.promise.then ->
      $http.post('/checklist', { contractor_id: $scope.user.id, job_id: $scope.job.id }).success (rsp) ->
        if rsp
          $scope.checklist = rsp
          _($scope.checklist.checklist_settings).each (v,k) ->
            _(v).each (v2, k2) ->
              $scope.$watch "checklist.checklist_settings.#{k}.#{k2}", (n,o) -> if n != o
                $http.post('/checklist/update', {
                  contractor_id: $scope.user.id,
                  job_id: $scope.job.id,
                  type: 'setting',
                  category: k,
                  item: k2
                  value: n
                })

  $scope.completed_job = ->
    $scope.job and $scope.job.status_cd == 3

  $scope.cancellable = ->
    $scope.job && ($scope.job.status_cd == 0 || $scope.job.status_cd == 1)

  $scope.arrived = ->
    angular.element('.arrived-dropdown').css 'max-height', 80
    null

  $scope.close_dialog = -> ngDialog.closeAll()

  $scope.start = ->
    ngDialog.open template: 'begin-job-modal', className: 'success full', scope: $scope

  $scope.confirm_start = ->
    ngDialog.closeAll()
    params = {}
    params.issue_resolved = true if $scope.resolved
    $http.post("/jobs/#{$scope.job.id}/begin", params).success (rsp) ->
      $scope.job.status_cd = rsp.status_cd
      $http.get($window.location.href + '/status').success (rsp) ->
        $scope.job.status = rsp.status
        $scope.job.blocker = rsp.blocker
    angular.element('.actions .phase.active .header').removeClass 'warning'
    angular.element('.actions .phase.active').removeClass('active').addClass('complete').find('.header .text').text 'Job in Progress...'
    angular.element('.actions .phase.arrival').addClass('active')
    null

  $scope.issue_resolved = ->
    $scope.resolved = true
    $scope.start()

  $scope.can_access = ->
    text = angular.element('timer').text()
    if text == '00:00'
      true
    else
      false

  $scope.cant_access_modal = ->
    ngDialog.open template: 'cant-access-modal', className: 'info full', scope: $scope

  $scope.occupied_modal = ->
    ngDialog.open template: 'occupied-modal', className: 'info full', scope: $scope

  $scope.cant_access = (type) ->
    ngDialog.closeAll()
    params = {}
    params.property_occupied = true if type is 'property_occupied'
    spinner.startSpin()
    $http.post("/jobs/#{$scope.job.id}/cant_access", params).success (rsp) ->
      $scope.job.status_cd = rsp.status_cd
      $scope.job.cant_access_seconds_left = rsp.seconds_left
      $http.get($window.location.href + '/status').success (rsp) ->
        spinner.stopSpin()
        $scope.job.status = rsp.status
        $scope.job.blocker = rsp.blocker

  $scope.timer_finished = ->
    if $scope.job.status_cd == 5
      $http.post("/jobs/#{$scope.job.id}/timer_finished")

  $scope.call = ->
    $http.post("/jobs/#{$scope.job.id}/call")

  $scope.sms = ->
    $http.post("/jobs/#{$scope.job.id}/sms")

  $scope.in_progress = ->
    if $scope.job
      $scope.job.status_cd == 2 && 'active' || ''
    else
      ''

  $scope.cancel_modal = ->
    ngDialog.open template: 'cancel-job-modal', className: 'warning full', scope: $scope

  $scope.close_cancellation = ->
    ngDialog.closeAll()

  $scope.confirm_cancellation = ->
    $http.post("/jobs/#{$scope.job.id}/drop").success (rsp) -> $window.location = '/'

  $scope.pricing_class = ->
    if $scope.staging
      'staging'
    else if $scope.vip
      'vip'
    else
      ''

  $scope.to_arrival_tasks = -> $scope.arrival = false

  $scope.show_applicant = ->
    $scope.job and $scope.job.applicants and $scope.job.applicants.length > 0 and $scope.job.training

  $scope.show_mentor = ->
    $scope.job and $scope.job.mentors and $scope.job.mentors.length > 0 and $scope.job.training

  $scope.show_team = ->
    $scope.job and $scope.job.team_members and $scope.job.team_members.length > 0 and !$scope.job.training

  $scope.in_arrival_tasks = ->
    unless $scope.arrival_tasks() && $scope.damage_inspection() && $scope.inventory_count() && $scope.arrival
      true
    else
      false

  $scope.check = (task) -> task && 'complete' || ''

  $scope.arrival_tasks = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.arrival_tasks
      if _($scope.checklist.checklist_settings.arrival_tasks).filter((v,k) -> v).length < 2 then false else true
    else
      false

  $scope.damage_inspection = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.damage_inspection
      if $scope.checklist.checklist_settings.damage_inspection.damage
        if $scope.checklist.contractor_photos[0]
          true
        else
          false
      else
        true
    else
      false

  $scope.inventory_count = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.inventory_count
      $scope.checklist.checklist_settings.inventory_count.complete
    else
      false

  $scope.arrival_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress()
      if $scope.in_arrival_tasks()
        'active'
      else if $scope.inventory_count()
        'complete'
      else
        ''

  $scope.cleaning_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress() && $scope.inventory_count()
      if $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.cleaning.cleaned
        'complete'
      else
        'active'
    else
      ''

  $scope.qa_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress() && $scope.checklist && $scope.checklist.checklist_settings
      if $scope.checklist.checklist_settings.cleaning.cleaned then 'active' else ''
    else
      ''

  $scope.damage_class = -> if $scope.in_progress() && $scope.arrival_tasks() then '' else 'disabled'
  $scope.inventory_class = -> if $scope.in_progress() && $scope.damage_inspection() then '' else 'disabled'
  $scope.begin_cleaning_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.inventory_count
      ''
      #inventory = $scope.checklist.checklist_settings.inventory_count
      #sheets = inventory.king_sheets > 0 || inventory.twin_sheets > 0
      #pillows = inventory.pillow_count > 0
      #towels = inventory.bath_towels > 0 || inventory.hand_towels > 0 || inventory.face_towels > 0 || inventory.bath_mats > 0
      #if towels && sheets && pillows then '' else 'disabled'
    else
      'disabled'

  $scope.complete_cleaning_class = -> ''

  $scope.damage_photos_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.damage_inspection
      if $scope.checklist.checklist_settings.damage_inspection.damage
        'active'
      else
        ''
    else
      ''

  $scope.photos_class = ->
    if $scope.checklist && $scope.checklist.kitchen_photo.url && $scope.checklist.bedroom_photo.url && $scope.checklist.bathroom_photo.url
      ''
    else
      'disabled'

  $scope.room_class = (tab, num) ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings[tab]).filter((v,k) -> v).length == num
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.sector_class = (tab, num) ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings[tab]).filter((v,k) -> v).length >= num
        'visible'
      else
        ''
    else
      ''

  $scope.complete_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if $scope.room_class('living_room', 3) == '' && $scope.room_class('kitchen', 11) == '' && $scope.photos_class() == '' &&
         $scope.room_class('bathroom_' + $scope.job.booking.property.bathrooms, 9) == '' &&
         $scope.room_class('bedroom_' + $scope.job.booking.property.checklist_bedrooms, 9) == ''
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.circle_class = (tab, num) ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings[tab]).filter((v,k) -> v).length == num
        'complete'
      else
        ''
    else
      ''

  $scope.circle_photos_class = ->
    if $scope.checklist && ($scope.checklist.kitchen_photo.url || ($scope.kitchen_photo && $scope.kitchen_photo[0])) && ($scope.checklist.bedroom_photo.url || ($scope.bedroom_photo && $scope.bedroom_photo[0])) && ($scope.checklist.bathroom_photo.url || ($scope.bathroom_photo && $scope.bathroom_photo[0]))
      'complete'
    else
      ''

  $scope.sector_photos_class = (num) ->
    if $scope.checklist
      count = 0
      count += 1 if $scope.checklist.kitchen_photo.url  || ($scope.kitchen_photo && $scope.kitchen_photo[0])
      count += 1 if $scope.checklist.bedroom_photo.url  || ($scope.bedroom_photo && $scope.bedroom_photo[0])
      count += 1 if $scope.checklist.bathroom_photo.url || ($scope.bathroom_photo && $scope.bathroom_photo[0])
      if count >= num
        'visible'
      else
        ''
    else
      ''

  $scope.to_tab = (tab, phase) ->
    angular.element(".phase.#{phase} .tab").removeClass 'active'
    angular.element(".phase.#{phase} .tab.#{tab}").addClass 'active'
    null

  $scope.to_damage = ->
    if $scope.damage_class() == ''
      angular.element(".phase.arrival .tab").removeClass 'active'
      angular.element(".phase.arrival .tab.damage").addClass 'active'
      null

  $scope.to_inventory = ->
    if $scope.inventory_class() == ''
      angular.element(".phase.arrival .tab").removeClass 'active'
      angular.element(".phase.arrival .tab.inventory").addClass 'active'
      null

  $scope.to_cleaning = ->
    if $scope.begin_cleaning_class() == ''
      $scope.checklist.checklist_settings.inventory_count.complete = true
      $scope.arrival = true
      scroll '.phase.cleaning'
    null

  $scope.complete_cleaning = -> $scope.checklist.checklist_settings.cleaning.cleaned = true

  $scope.complete_bedroom = (num) ->
    if $scope.room_class('bedroom_' + num, 9) == ''
      if num == $scope.job.booking.property.checklist_bedrooms
        angular.element('.phase.qa .tab').removeClass 'active'
        angular.element('.phase.qa .tab.bathrooms').addClass 'active'
      else
        $scope.active_bedroom += 1
      scroll '.phase.cleaning'
    null

  $scope.complete_bathroom = (num) ->
    if $scope.room_class('bathroom_' + num, 9) == ''
      if num == $scope.job.booking.property.bathrooms
        angular.element('.phase.qa .tab').removeClass 'active'
        angular.element('.phase.qa .tab.kitchen').addClass 'active'
        angular.element('.phase.qa .tab.bathrooms .progress_circle').addClass 'complete'
        null
      else
        $scope.active_bathroom += 1
      scroll '.phase.cleaning'
    null

  $scope.complete_kitchen = ->
    if $scope.room_class('kitchen', 11) == ''
      angular.element('.phase.qa .tab').removeClass 'active'
      angular.element('.phase.qa .tab.living-room').addClass 'active'
      scroll '.phase.cleaning'
      null

  $scope.complete_living = ->
    if $scope.room_class('living_room', 3) == ''
      angular.element('.phase.qa .tab').removeClass 'active'
      angular.element('.phase.qa .tab.photos').addClass 'active'
      scroll '.phase.cleaning'
      null

  $scope.complete_job = ->
    if $scope.complete_class() == ''
      spinner.startSpin()
      $http.post("/jobs/#{$scope.job.id}/complete").success (_rsp) ->
        $scope.next_job = _rsp.next_job

        $http.get($window.location.href + '/status').success (rsp) ->
          spinner.stopSpin()
          $scope.job.status_cd = _rsp.status_cd
          $scope.job.status = rsp.status
          $scope.job.blocker = rsp.blocker

  $scope.range = (n) -> if n then _.range 0, n else []

  $scope.bedroom_checklist_class = (n) -> if n == $scope.active_bedroom then 'active' else ''
  $scope.bathroom_checklist_class = (n) -> if n == $scope.active_bathroom then 'active' else ''

  $scope.$watch 'damage_photo', ->
    if $scope.damage_photo && $scope.damage_photo[0]
      spinner.startSpin()
      $upload.upload(
        url: '/checklist/damage_photo'
        fields: { contractor_id: $scope.user.id, job_id: $scope.job.id }
        file: $scope.damage_photo[0]
      ).success (rsp) ->
        spinner.stopSpin()
        if rsp.success
          $scope.checklist.contractor_photos = rsp.contractor_photos
        else
          flash 'failure', rsp.message

  $scope.$watch 'kitchen_photo', ->
    if $scope.kitchen_photo && $scope.kitchen_photo[0]
      spinner.startSpin()
      data = {success_action_status: 201}
      _(angular.element('#kitchen_photo :input').serializeArray()).each (h) -> data[h.name] = h.value
      action = angular.element('#kitchen_photo').attr 'action'
      $upload.upload({
        url: action,
        method: 'POST',
        fields: data,
        file: $scope.kitchen_photo[0]
      }).success (xml) ->
        spinner.stopSpin()
        key = $($.parseXML xml).find('Key').text()
        $http.post($window.location.href + '/snap_photo', {key: key, checklist_id: $scope.checklist.id, room: 'kitchen'})
          .success (rsp) ->
            angular.element('.snap-photo.kitchen .icon').css 'display', 'none'
            angular.element('.snap-photo.kitchen .new-photo').css 'background-image', "url(#{rsp.url})"
            angular.element('.snap-photo.kitchen img').attr 'src', rsp.url

  $scope.$watch 'bedroom_photo', ->
    if $scope.bedroom_photo && $scope.bedroom_photo[0]
      spinner.startSpin()
      data = {success_action_status: 201}
      _(angular.element('#bedroom_photo :input').serializeArray()).each (h) -> data[h.name] = h.value
      action = angular.element('#bedroom_photo').attr 'action'
      $upload.upload({
        url: action,
        method: 'POST',
        fields: data,
        file: $scope.bedroom_photo[0]
      }).success (xml) ->
        spinner.stopSpin()
        key = $($.parseXML xml).find('Key').text()
        $http.post($window.location.href + '/snap_photo', {key: key, checklist_id: $scope.checklist.id, room: 'bedroom'})
          .success (rsp) ->
            angular.element('.snap-photo.bedroom .icon').css 'display', 'none'
            angular.element('.snap-photo.bedroom .new-photo').css 'background-image', "url(#{rsp.url})"
            angular.element('.snap-photo.bedroom img').attr 'src', rsp.url

  $scope.$watch 'bathroom_photo', ->
    if $scope.bathroom_photo && $scope.bathroom_photo[0]
      spinner.startSpin()
      data = {success_action_status: 201}
      _(angular.element('#bathroom_photo :input').serializeArray()).each (h) -> data[h.name] = h.value
      action = angular.element('#bathroom_photo').attr 'action'
      $upload.upload({
        url: action,
        method: 'POST',
        fields: data,
        file: $scope.bathroom_photo[0]
      }).success (xml) ->
        spinner.stopSpin()
        key = $($.parseXML xml).find('Key').text()
        $http.post($window.location.href + '/snap_photo', {key: key, checklist_id: $scope.checklist.id, room: 'bathroom'})
          .success (rsp) ->
            angular.element('.snap-photo.bathroom .icon').css 'display', 'none'
            angular.element('.snap-photo.bathroom .new-photo').css 'background-image', "url(#{rsp.url})"
            angular.element('.snap-photo.bathroom img').attr 'src', rsp.url

  scroll = (target) -> angular.element('body').scrollTo(angular.element("#{target}"), 600)

]

app = angular.module('porter').controller('job', JobCtrl)
