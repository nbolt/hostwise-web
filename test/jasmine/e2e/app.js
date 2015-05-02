describe('hostwise', function(){
  beforeAll(function(){
    browser.get('/')
    browser.waitForAngular()
    $('nav .login').click()
    browser.driver.wait(function(){ return browser.driver.isElementPresent(by.css('.signin.modal')) }, 10000)
    $('.signin.modal .field.email input').sendKeys('test@email.com')
    $('.signin.modal .field.password input').sendKeys('test')
    $('.signin.modal form button').click()
  })

  it('be signed in', function(){
    expect(browser.getCurrentUrl()).toBe('http://host.hostwise-web.dev:3000/properties/first')
  })
})