# frozen_string_literal: true

class Parent::ForumCommentsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("parent") }
  before_action :set_forum
  before_action :set_comment, only: [ :destroy ]

  def create
    @comment = @forum.parent_forum_comments.build(comment_params)
    @comment.created_by = current_user

    if @comment.save
      redirect_to parent_forum_path(@forum), notice: "댓글이 작성되었습니다."
    else
      @current_page = "forums"
      @comments = @forum.parent_forum_comments
                        .includes(:created_by)
                        .recent
      @new_comment = @comment
      render "parent/forums/show", status: :unprocessable_entity
    end
  end

  def destroy
    unless @comment.created_by_id == current_user.id
      redirect_to parent_forum_path(@forum), alert: "권한이 없습니다."
      return
    end

    @comment.destroy
    redirect_to parent_forum_path(@forum), notice: "댓글이 삭제되었습니다."
  end

  private

  def set_forum
    @forum = ParentForum.find(params[:forum_id])
  end

  def set_comment
    @comment = @forum.parent_forum_comments.find(params[:id])
  end

  def comment_params
    params.require(:parent_forum_comment).permit(:content)
  end
end
