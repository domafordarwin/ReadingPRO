# frozen_string_literal: true

class DiagnosticTeacher::ConsultationCommentsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_consultation_post

  def create
    @comment = @post.consultation_comments.build(comment_params)
    @comment.created_by = current_user

    if @comment.save
      redirect_to diagnostic_teacher_consultation_path(@post), notice: "답변이 작성되었습니다."
    else
      @current_page = "consultations"
      @comments = @post.consultation_comments
                       .includes(:created_by)
                       .recent
      @new_comment = @comment
      render "diagnostic_teacher/consultations/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment = @post.consultation_comments.find(params[:id])

    if @comment.created_by_id == current_user.id
      @comment.destroy
      redirect_to diagnostic_teacher_consultation_path(@post), notice: "답변이 삭제되었습니다."
    else
      redirect_to diagnostic_teacher_consultation_path(@post), alert: "권한이 없습니다."
    end
  end

  private

  def set_consultation_post
    @post = ::ConsultationPost.find(params[:consultation_id])
  end

  def comment_params
    params.require(:consultation_comment).permit(:content)
  end
end
