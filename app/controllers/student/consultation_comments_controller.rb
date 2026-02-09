# frozen_string_literal: true

class Student::ConsultationCommentsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("student") }
  before_action :set_student
  before_action :set_consultation_post
  before_action :authorize_reply

  def create
    @comment = @post.consultation_comments.build(comment_params)
    @comment.created_by = current_user

    if @comment.save
      redirect_to student_consultation_path(@post), notice: "댓글이 작성되었습니다."
    else
      @current_page = "feedback"
      @comments = @post.consultation_comments
                       .includes(:created_by)
                       .recent
      @new_comment = @comment
      render "student/consultations/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment = @post.consultation_comments.find(params[:id])

    unless @post.can_reply?(current_user)
      redirect_to student_consultations_path, alert: "댓글 삭제 권한이 없습니다."
      return
    end

    if @comment.created_by_id == current_user.id
      @comment.destroy
      redirect_to student_consultation_path(@post), notice: "댓글이 삭제되었습니다.", status: :see_other
    else
      redirect_to student_consultation_path(@post), alert: "권한이 없습니다.", status: :see_other
    end
  end

  private

  def set_student
    @student = current_user&.student
  end

  def set_consultation_post
    @post = ::ConsultationPost.find(params[:consultation_id])
  end

  def authorize_reply
    unless @post.can_reply?(current_user)
      redirect_to student_consultations_path, alert: "댓글을 작성할 권한이 없습니다."
    end
  end

  def comment_params
    params.require(:consultation_comment).permit(:content)
  end
end
