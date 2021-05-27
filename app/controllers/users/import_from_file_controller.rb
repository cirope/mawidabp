class Users::ImportFromFileController < ApplicationController

  def new
  end

  def create
    @imports = User.import_from_file
  end
end
