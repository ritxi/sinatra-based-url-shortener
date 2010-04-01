require File.dirname(__FILE__) + '/spec_helper'

describe SinatraBasedUrlShortener do

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

end
