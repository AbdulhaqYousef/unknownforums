class SubforumsController < ApplicationController
  def show
    @subforum = Subforum.includes(:category).find(params[:id])
    @threads = @subforum.forum_threads
                        .includes(:user, :posts)
                        .order(pinned: :desc, updated_at: :desc)
                        .page(params[:page])
  end
end
