%w( unique_slug url click http_basic_auth ).each {|file| require File.dirname(__FILE__) + "/#{file}" }

class SinatraBasedUrlShortener < Sinatra::Base

  class << self
    attr_accessor :ssl_required, :basic_auth_required

    def ssl_required?
      (ssl_required == true) ? true : false
    end

    def basic_auth_required?
      (basic_auth_required == true) ? true : false
    end
  end

  get '/' do
    haml :index
  end

  post '/' do
    protected! if SinatraBasedUrlShortener.basic_auth_required?

    if SinatraBasedUrlShortener.ssl_required?
      # HTTP_X_FORWARDED_PROTO is set by Heroku (the scheme will show up as http)
      using_ssl = (request.scheme == 'https')
      using_ssl = (request.env['HTTP_X_FORWARDED_PROTO'] == 'https') unless using_ssl

      unless using_ssl
        status 403
        return "SSL Required"
      end
    end

    @url = Url.shorten params[:url]
    haml :index
  end

  get '/:slug/history' do |slug|
    @url = Url.first :slug => slug
    haml :history
  end

  get '/:slug' do |slug|
    @url = Url.first :slug => slug
    if @url
      @url.clicks.create :ip_address => request.ip, :referrer => request.referrer
      redirect @url.url
    else
      status 404
      "Not Found"
    end
  end

  helpers do
    include HttpBasicAuth # username and password are set in this module

    def full_url slug
      'http://' + request.host + '/' + slug
    end

    def ssl_path path
      if SinatraBasedUrlShortener.ssl_required?
        'https://' + request.host + path
      else
        path
      end
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
%form{ :action => ssl_path('/'), :method => 'post' }
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
        (
        %a{ :href => "/#{ url.slug }/history" } history
        )

@@ history
%dl
  %dt Url
  %dd
    %a{ :href => @url.url }= @url.url

  %dt Shortened
  %dd
    %a{ :href => full_url(@url.slug) }= full_url(@url.slug)

  %dt Number of times visited
  %dd= @url.clicks.count

  %dt Recent history
  %dd
    %ul
      - for click in @url.clicks.all(:limit => 10, :order => :created_at.desc)
        %li== #{ click.ip_address } at #{ click.created_at } from #{ click.referrer }
