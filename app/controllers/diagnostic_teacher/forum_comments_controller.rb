# frozen_string_literal: true

class DiagnosticTeacher::ForumCommentsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_forum
  before_action :set_comment, only: [ :destroy ]

  def create
    @comment = @forum.parent_forum_comments.build(comment_params)
    @comment.created_by = current_user
    @comment.is_teacher_reply = true

    if @comment.save
      # 댓글 작성 시 게시글 상태를 'answered'로 변경
      @forum.mark_as_answered! unless @forum.answered?
      redirect_to diagnostic_teacher_forum_path(@forum), notice: "답변이 작성되었습니다."
    else
      @current_page = "forums"
      @comments = @forum.parent_forum_comments
                        .includes(:created_by)
                        .recent
      @new_comment = @comment
      render "diagnostic_teacher/forums/show", status: :unprocessable_entity
    end
  end

  def destroy
    unless @comment.created_by_id == current_user.id
      redirect_to diagnostic_teacher_forum_path(@forum), alert: "권한이 없습니다.", status: :see_other
      return
    end

    @comment.destroy
    redirect_to diagnostic_teacher_forum_path(@forum), notice: "댓글이 삭제되었습니다.", status: :see_other
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
