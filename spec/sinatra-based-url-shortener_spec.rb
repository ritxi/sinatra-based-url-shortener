require File.dirname(__FILE__) + '/spec_helper'

describe SinatraBasedUrlShortener do
  include Rack::Test::Methods

  # for Rack::Test (which lets us test the response code, because Capybara doesn't support this)
  def app
    SinatraBasedUrlShortener.new
  end

  before do
    UniqueSLUG.all.destroy
  end

  it 'should be able to shorten a URL' do
    Url.count.should == 0

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1
    Url.first.url.should  == 'http://www.google.com'
    Url.first.slug.should == 'aaa'

    visit '/'
    fill_in 'url', :with => 'http://www.not-google.com'
    click_button 'Shorten'

    Url.count.should == 2
    Url.last.url.should  == 'http://www.not-google.com'
    Url.last.slug.should == 'aab'
  end

  it 'should return the same unique slug for identical URLs' do
    Url.count.should == 0

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1
    Url.first.url.should  == 'http://www.google.com'
    Url.first.slug.should == 'aaa'

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.count.should == 1 # did not create a new one
  end

  it 'should redirect you to the full URL when you visit the slug' do
    get '/aaa'
    last_response.status.should == 404

    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'
    
    get '/aaa'
    last_response.status.should == 302
    last_response.headers['Location'].should == 'http://www.google.com'
  end

  it 'tracks clicked URLs' do
    visit '/'
    fill_in 'url', :with => 'http://www.google.com'
    click_button 'Shorten'

    Url.first.clicks.count.should == 0
    
    get '/aaa'
    Url.first.clicks.count.should == 1
    Url.first.clicks.first.ip_address.should == '127.0.0.1'
    Url.first.clicks.first.created_at.should_not be_nil
    Url.first.clicks.first.referrer.should == '/'

    get '/aaa'
    Url.first.clicks.count.should == 2
  end

end
