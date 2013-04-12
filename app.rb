require 'capybara/poltergeist'
Capybara.run_server = false
Capybara.current_driver = :poltergeist

module SolveCaptcha
  include Capybara::DSL
  
  def captcha_solution
    page.save_screenshot('captcha.png', :full => true)
    `open captcha.png`
    puts "Looks like they don't trust you! Solve the caption in the opened image: "
    gets
  end

end

module DSA_Website 
  include Capybara::DSL
  include SolveCaptcha

  def login_with(details)
    Capybara.reset_sessions!

    visit 'https://driverpracticaltest.direct.gov.uk/login'
    fill_in 'driving-licence-number', :with => details[:license]
    fill_in 'application-reference-number', :with => details[:reference]

    if page.has_content? 'Please type both words you see in the box'
      fill_in 'recaptcha_response_field', :with => captcha_solution 
    end

    click_on 'booking-login'

    Capybara.using_wait_time 30 do
      page.has_content? 'View booking'
    end
  end

  def find_earliest_practical_test
    visit 'https://www.gov.uk/change-date-practical-driving-test'
    click_on 'Start now'
    click_link 'date-time-change'
    click_on 'Find available dates'

    if page.has_content? 'Please complete the additional security question'
      fill_in 'recaptcha_response_field', :with => captcha_solution
      click_on 'Validate'
    end

    Capybara.using_wait_time 30 do
      page.has_content? 'Found earliest available tests'
    end

    page.save_screenshot('earliest_slots.png', :full => true)
  end

end

class Application
  include DSA_Website

  def run!
    login_with my_details 
    find_earliest_practical_test
  end

  def my_details
    puts "What's your driving license id? (e.g. FETT089809880)"
    id = gets
    puts "What's your booking reference? (e.g. 12345678)"
    ref = gets

    { :license => id, :reference => ref }
  end
end

app = Application.new
app.run!
