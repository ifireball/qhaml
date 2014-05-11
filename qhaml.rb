#!/usr/bin/env ruby
# qhaml.rb - Quick and dirty Sinatra-based haml editor
#
require "bundler"

require 'opal'
require 'opal-jquery'
require 'opal-haml'
require 'sinatra'
require 'sprockets'
require 'sinatra/asset_pipeline'
require 'sequel'

before do
  settings.db.loggers << logger unless settings.db.loggers.include?(logger)
  # TODO: Move defaults to model
  defaults = {
    :page_format => 'HAML',
    :script_format => 'OPAL',
    :style_format => 'CSS',
    :name => 'Unnamed project',
  }
  @user = User[session[:user_id]] || User[:name => '<dummy>'] ||
    User.new(:name => '<dummy>', :password => '<dummy>')
  @project = @user.last_project ||=
    Project.new(:temporary => true).
    set(Hash[Project.editable_columns.map do |attr|
      [attr, (erb(:"default_#{attr}", :layout => false) rescue nil) ||
        defaults[attr] || ""
      ]
    end]).save
  if @user.modified?
    @user.save 
    @project.update(:user_id => @user.id)
  end
end

after do
  session[:user_id] = @user.id
  settings.db.loggers.delete(logger)
end

get '/' do
  haml :frameset, :layout => false
end

get '/editor' do
  haml :editor
end

get %r{/viewer(?:/(page|style|script))?} do |what|
  what =  (what || :page).to_sym
  src = @project[:"#{what}_src"]
  format = @project[:"#{what}_format"]
  content_type what
  case format
  when 'CSS'        then src
  when 'SCSS'       then scss src
  when 'LESS'       then less src
  when 'OPAL'       then Opal.compile(src)
  when 'JavaScript' then src
  when 'HTML'
    if src.match(/\A\s*<(DOCTYPE|html)/)
      src
    else
      haml :"viewer-layout", :layout => false do
        src 
      end
    end
  when 'HAML'
    haml src, :layout => (!src.match(/\A\s*!!!/) and :"viewer-layout")
  end
end

post '/action' do
  @project.update_fields_from(params)
  case params[:action]
  when 'save'
    @user.save_project(@project)
  when 'evaluate'
  else
    @user.saved_projects_dataset[:id => params[:"action-delete"]].destroy
  end
  redirect to('/viewer')
end

get '/load/:project_id' do |project_id|
  loaded = @user.saved_projects_dataset[:id => project_id] or halt 404 #TODO: error page
  @project.update_fields_from(loaded)
  redirect to('/')
end

get %r{^/__opal_source_maps__/(.*)} do 
  path_info = params[:captures].first
  logger.info "Source map requested: #{path_info}"
  if path_info =~ /\.js\.map$/
    path = path_info.gsub(/^\/|\.js\.map$/, '')
    asset = settings.sprockets[path]
    raise Sinatra::NotFound if asset.nil?
    headers "Content-Type" => "text/json"
    body $OPAL_SOURCE_MAPS[asset.pathname].to_s
  else
    send_file settings.sprockets.resolve(path_info), :type => 'text/text'
  end
end

configure do
  set :port, 1234
  set :sprockets, Opal::Environment.new
  set :digest_assets, true
  set :session_secret, 'QHaml secret'

  mime_type :page, 'text/html'
  mime_type :style, 'text/css'
  mime_type :script, 'application/javascript'
end

module Sinatra
  register Sinatra::AssetPipeline
end

configure :development do
  set :db, Sequel.connect('mysql2://qhaml:qhaml@localhost/qhaml')
  Sprockets::Helpers.expand = true
  require 'model'
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
  def main_editor(editor_for)
    name    = :"#{editor_for}_src"
    content = @project[:"#{editor_for}_src"]
    format  = @project[:"#{editor_for}_format"]
    haml :main_editor, :layout => false,
      :locals => Hash[(local_variables - [:_]).map {|v| [v,eval(v.to_s)]}]
  end
  def language_selector(select_for)
    name = :"#{select_for}_format"
    value = @project[name]
    options, title = {
      :page   => [%w{HAML HTML}, "Select markup language"],
      :script => [%w{OPAL JavaScript}, "Select script language"],
      :style  => [%w{CSS SCSS LESS}, "Select styling language"],
    }[select_for]
    haml :language_selector, :layout => false, 
      :locals => Hash[(local_variables - [:_]).map {|v| [v,eval(v.to_s)]}]
  end
  def project_link(project, display_str = nil)
    "<a href=\"#{url("/load/" + project.id.to_s)}\" " + 
      "target=\"_top\"" +
      "title=\"Load project: #{project.name}\">" + 
      h(display_str || project.name) +
    "</a>"
  end
  def date_format(date)
    date.strftime("%h %d, %Y, %H:%M")
  end
end

__END__

@@default_page_src
.container 
  .row
    .jumbotron
      %h1 QHaml
      %p Just type HAML into the form below and click submit

@@main_editor
%textarea.main-editor{:name => name, :rows => 10, :data => {:format => format}}= content

@@language_selector
%select.invisible-control.hidden-noactive-inline-xs{:name => name, :title => title}
  - options.each do |option|
    %option{:selected => (value == option)}= option

@@opal_wrapper
require 'opal'
require 'opal-jquery'

Document.ready? do
  body = Element['.results-body']
  begin
    result = %x{<%= @script %>}
    body << Element["<h1>Results</h1>"]
    body << Element["<h2>Inspect:</h2>"]
    body << Element["<pre>"].text(result.inspect)
    body << Element["<h2>Class:</h2>"]
    body << Element["<p>"].text(result.class)
    if result.is_a?(Enumerable)
      body << Element["<h2>Members:</h2>"]
      body << (
        Element['<ul class="members">'] <<
        result.map do |m|
          Element['<li>'] << Element['<code>'].text(m.inspect)
        end
      )
    end
  rescue Exception => e
    body << Element["<h1>"].text(e.class)
    body << Element["<h2>"].text(e.message)
    body << (
      Element['<ul class="backtrace">'] <<
      e.backtrace.map do |bt|
        Element['<li>'].text(bt)
      end
    )
  end
end

@@opal_evaluator
- @compiler.requires.uniq.each do |r|
  = javascript_tag r
.container
  .row.results-body
%script{:language => 'javascript'}= @wrapper

