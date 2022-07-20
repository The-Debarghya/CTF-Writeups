#!/usr/bin/env ruby -wKU
require "sinatra"
require_relative "main.rb"
require_relative "viewUtil.rb"

get '/uploads' do
  @error = "An #{params[:error]} error has occurred." if params[:error]
  @pipelines = Upload.all.inject([]) do |a, upload|
    a << Pipeline.run(File.read(upload.file_path), upload.user, upload.trial)
    a
  end

  erb :uploads
end

get '/upload/*' do |file_path|
  upload = Upload.find(file_path)
  @pipeline = Pipeline.run(File.read(file_path), upload.user, upload.trial)

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
