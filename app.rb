#!/usr/bin/env ruby -wKU
require "sinatra"
require "logger"
require_relative "main.rb"
require_relative "viewUtil.rb"
class Application < Sinatra::Base

  ::Logger.class_eval { alias :write :'<<' }
  access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','access.log')
  access_logger = ::Logger.new(access_log)
  error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','error.log'),"a+")
  error_logger.sync = true

  configure do
    use ::Rack::CommonLogger, access_logger
  end

  before {
    env["rack.errors"] =  error_logger
  }

  get '/uploads' do
    @error = "An #{params[:error]} error has occurred." if params[:error]
    @pipelines = Upload.all.inject([]) do |a, upload|
      a << Pipeline.run(upload.file_path, upload.user, upload.trial)
      a
    end

    erb :uploads
  end

  get '/upload/*' do |file_path|
    if file_path.include? "styles.css"
      next
    end
    upload = Upload.find(file_path)
    @pipeline = Pipeline.run(upload.file_path, upload.user, upload.trial)

    erb :upload
  end

  post '/create' do
    begin
      Upload.create(params[:data][:tempfile], params[:user], params[:trial])

      redirect '/uploads'

    rescue Exception => e
      redirect '/uploads?error=creation'

    end
  end
end
