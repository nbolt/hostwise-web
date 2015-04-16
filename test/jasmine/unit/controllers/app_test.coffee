describe 'AppCtrl', ->
  beforeEach module('porter')

  $controller        = null
  $rootScope         = null
  $httpBackend       = null
  authRequestHandler = null
  createController   = null

  beforeEach inject(($injector, ngMock) ->
    $controller  = $injector.get('$controller')
    $rootScope = $injector.get('$rootScope')
    $httpBackend = $injector.get('$httpBackend')

    createController = -> $controller('AppCtrl', {'$scope' : $rootScope })

    authRequestHandler = $httpBackend.when('GET', '/auth.py')
      .respond({userId: 'userX'}, {'A-Token': 'xxx'});
  )

  afterEach inject( (ngMock) ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
  )

  it 'should be awesome', inject( (ngMock) ->
    $httpBackend.expectGET('/auth.py');
    controller = createController()
    $httpBackend.flush()
  )