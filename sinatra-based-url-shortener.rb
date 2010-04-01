%w( rubygems sinatra/base haml dm-core dm-aggregates dm-validations dm-timestamps ).each {|lib| require lib }
require File.dirname(__FILE__) + '/unique_slug'
require File.dirname(__FILE__) + '/url'

class SinatraBasedUrlShortener < Sinatra::Base

  get '/' do
    haml :index
  end

  post '/' do
    @url = Url.shorten params[:url]
    haml :index
  end

  get '/:slug' do |slug|
    @url = Url.first :slug => slug
    if @url
      redirect @url.url
    else
      status 404
      "Not Found"
    end
  end

  helpers do
    def full_url slug
      'http://' + request.host + '/' + slug
    end
  end

  use_in_file_templates!

end

__END__

@@ layout
!!! XML
!!! Strict
%html
  %head
    %title Sinatra Based URL Shortener
  %body
    = yield

@@ index
%form{ :action => '/', :method => 'post' }
  %label
    URL to Shorten
    %input{ :type => 'text', :placeholder => 'http://www.google.com/', :autofocus => true, :name => 'url', :id => 'url', :value => (@url ? @url.url : '') }
  %input{ :type => 'submit', :value => 'Shorten' }

- if @url
  %p
    Shortened URL:
    %a{ :href => full_url(@url.slug) }= full_url(@url.slug)

%p
  = Url.count
  URLs shortened

- if Url.count > 0
  %p Recently shortened URLs
  %ul
    - for url in Url.all(:limit => 10, :order => :created_at.desc)
      %li
        %a{ :href => full_url(url.slug) }= url.url
