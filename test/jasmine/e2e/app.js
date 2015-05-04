describe('hostwise', function(){
  beforeAll(function(){
    browser.driver.manage().window().maximize()
    browser.get('/')
    browser.waitForAngular()
    $('nav .login').click()
    browser.driver.wait(function(){ return browser.driver.isElementPresent(by.css('.signin.modal')) }, 10000)
    $('.signin.modal .field.email input').sendKeys('test@email.com')
    $('.signin.modal .field.password input').sendKeys('test')
    $('.signin.modal form button').click()
  })

  it('should be signed in', function(){
    expect(browser.getCurrentUrl()).toBe('http://host.hostwise-web.dev:3000/')
  })

  describe('new property flow:', function(){
    it('can enter property details', function(){
      $('#sidebar-container .section.new-property a').click()
      browser.waitForAngular()
      $('.property-form-container .step.one input#address1').sendKeys('338 Rennie Ave')
      $('.property-form-container .step.one input#address2').sendKeys('#3')
      $('.property-form-container .step.one input#zip_code').sendKeys('90291')
      $('.property-form-container .step.one input#contact_number').sendKeys('4157873660')
      $('.property-form-container .step.one input#nickname').sendKeys('HostWise')
      $('.property-form-container .step.one .section.action .icon-button').click()
      browser.waitForAngular()
      $('.property-form-container .step.two #bathrooms .select2-container a').click()
      $$('.select2-drop li').get(1).click()
      $('.property-form-container .step.two #bedrooms .select2-container a').click()
      $$('.select2-drop li').get(1).click()
      $('.property-form-container .step.two #kings .select2-container a').click()
      $$('.select2-drop li').get(1).click()
      $('.property-form-container .step.two .row > .icon-button').click()
      browser.waitForAngular()
      $$('.property-form-container .step.three textarea').get(0).sendKeys('?')
      $$('.property-form-container .step.three textarea').get(1).sendKeys('?')
      $$('.property-form-container .step.three textarea').get(2).sendKeys('?')
      $$('.property-form-container .step.three textarea').get(3).sendKeys('?')
      $('.property-form-container .step.three .row > .icon-button').click()
    })

    it('property saved successfully', function(){
      browser.get('/')
      expect($$('#properties .property').count()).toBe(1)
    })
  })

  describe('booking flow:', function(){
    it('can book successfully', function(){
      $('#sidebar-container .section.properties a').click()
      browser.waitForAngular()
      $('#properties .property').click()
      browser.waitForAngular()
      $('.column.cal table td.active.day').click()
      browser.waitForAngular()
      confirm = $('.content-group.static.next-day .action.confirm')
      confirm.isDisplayed().then(function(displayed){
        if (displayed){
          confirm.click()
          browser.waitForAngular()
        }
      })
      confirm = $('.content-group.static.same-day .action.confirm')
      confirm.isDisplayed().then(function(displayed){
        if (displayed){
          confirm.click()
          browser.waitForAngular()
        }
      })
      $('.content-group.step-one .foot .right .button').click()
      browser.waitForAngular()
      $('.content-group.step-additional .foot .right .button').click()
      browser.waitForAngular()
      $('.content-group.step-two .payment-tab.active #card-number').sendKeys('4242424242424242')
      $('.content-group.step-two .payment-tab.active #expiry-date').sendKeys('11/20')
      $('.content-group.step-two .payment-tab.active #cv-code').sendKeys('123')
      $('.content-group.step-two .foot .right .button').click()
      browser.driver.sleep(500)
      browser.waitForAngular()
      $('.content-group.static.booked').isDisplayed().then(function(displayed){
        expect(displayed).toBe(true)
      })
    })
  })
})