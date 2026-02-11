class Researcher::StimuliController < ApplicationController
  layout "unified_portal"
  skip_forgery_protection only: [:upload_answer_key, :upload_answer_template, :bulk_update_answers]
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_stimulus, only: %i[show edit update destroy analyze duplicate archive restore upload_answer_key bulk_update_answers download_answer_template upload_answer_template]
  before_action :set_role

  def show
    @current_page = "item_bank"
  end

  def new
    @stimulus = ReadingStimulus.new
  end

  def create
    sanitized = stimulus_params.dup
    sanitized[:body] = sanitize_body(sanitized[:body]) if sanitized[:body].present?

    @stimulus = ReadingStimulus.new(sanitized.except(:images))
    @stimulus.created_by_id = current_user.id if current_user

    if @stimulus.save
      # Attach images
      uploaded_images = params.dig(:reading_stimulus, :images)
      if uploaded_images.present?
        uploaded_images.reject(&:blank?).each do |img|
          begin
            @stimulus.images.attach(img)
          rescue => e
            Rails.logger.error "[Stimuli#create] Image attach error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          end
        end
      end
      redirect_to researcher_passages_path, notice: "지문이 성공적으로 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    sanitized = stimulus_params.dup
    sanitized[:body] = sanitize_body(sanitized[:body]) if sanitized[:body].present?

    # Attach new images
    image_errors = []
    uploaded_images = params.dig(:reading_stimulus, :images)
    if uploaded_images.present?
      uploaded_images.reject(&:blank?).each do |img|
        begin
          Rails.logger.info "[Stimuli#update] Attaching image: #{img.original_filename}, size=#{img.size}, content_type=#{img.content_type}"
          @stimulus.images.attach(img)
          Rails.logger.info "[Stimuli#update] Image attached successfully"
        rescue => e
          Rails.logger.error "[Stimuli#update] Image attach error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          image_errors << "이미지 '#{img.original_filename}' 업로드 실패: #{e.message}"
        end
      end
    end

    # Remove selected images
    if params[:remove_image_ids].present?
      params[:remove_image_ids].each do |img_id|
        begin
          blob = @stimulus.images.find { |i| i.id.to_s == img_id.to_s }
          blob&.purge
        rescue => e
          Rails.logger.error "[Stimuli#update] Image purge error: #{e.class}: #{e.message}"
        end
      end
    end

    if @stimulus.update(sanitized.except(:images))
      notice_msg = "지문이 성공적으로 수정되었습니다."
      notice_msg += " (주의: #{image_errors.join(', ')})" if image_errors.any?
      redirect_to researcher_passages_path, notice: notice_msg
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @stimulus.destroy
      redirect_to researcher_item_bank_path, notice: "모듈이 삭제되었습니다.", status: :see_other
    else
      redirect_to researcher_item_bank_path, alert: "모듈 삭제에 실패했습니다.", status: :see_other
    end
  end

  # AI Analysis endpoint
  def analyze
    begin
      result = @stimulus.analyze_with_ai!
      redirect_to researcher_item_bank_path, notice: "AI 분석이 완료되었습니다. (난이도: #{result[:difficulty_level]}, 영역: #{result[:domain]})"
    rescue => e
      Rails.logger.error "[AI Analysis] Error: #{e.message}"
      redirect_to researcher_item_bank_path, alert: "AI 분석 중 오류가 발생했습니다: #{e.message}"
    end
  end

  # Duplicate stimulus with all items
  def duplicate
    begin
      include_items = params[:include_items] != "false"
      new_stimulus = @stimulus.duplicate(include_items: include_items)

      if new_stimulus
        redirect_to researcher_passage_path(new_stimulus),
                    notice: "진단지 세트가 복제되었습니다. (#{new_stimulus.code})"
      else
        redirect_to researcher_passage_path(@stimulus),
                    alert: "복제에 실패했습니다."
      end
    rescue => e
      Rails.logger.error "[Stimulus#duplicate] Error: #{e.message}"
      redirect_to researcher_passage_path(@stimulus),
                  alert: "복제 중 오류가 발생했습니다: #{e.message}"
    end
  end

  # Archive stimulus (hide from list, but keep data)
  def archive
    if @stimulus.update(bundle_status: "archived")
      redirect_to researcher_item_bank_path,
                  notice: "진단지 세트가 보관처리 되었습니다. 지문과 문항 데이터는 유지됩니다."
    else
      redirect_to researcher_passage_path(@stimulus),
                  alert: "보관처리에 실패했습니다."
    end
  end

  # Restore stimulus from archive
  def restore
    if @stimulus.update(bundle_status: "draft")
      redirect_to researcher_passage_path(@stimulus),
                  notice: "진단지 세트가 복원되었습니다."
    else
      redirect_to researcher_passage_path(@stimulus),
                  alert: "복원에 실패했습니다."
    end
  end

  # Upload answer key PDF and auto-populate answers/rubrics
  def upload_answer_key
    Rails.logger.info "[Upload Answer Key] Action called, params: #{params.keys.join(', ')}"
    Rails.logger.info "[Upload Answer Key] answer_key_pdf present: #{params[:answer_key_pdf].present?}"

    unless params[:answer_key_pdf].present?
      Rails.logger.warn "[Upload Answer Key] No file provided"
      redirect_to researcher_passage_path(@stimulus), alert: "정답지 PDF 파일을 선택해주세요."
      return
    end

    uploaded_file = params[:answer_key_pdf]

    unless uploaded_file.content_type == "application/pdf"
      redirect_to researcher_passage_path(@stimulus), alert: "PDF 파일만 업로드할 수 있습니다."
      return
    end

    begin
      # Save uploaded file to temp location
      temp_path = Rails.root.join("tmp", "answer_key_#{Time.now.to_i}_#{uploaded_file.original_filename}")
      Rails.logger.info "[Upload Answer Key] Saving file to: #{temp_path}"
      File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }
      Rails.logger.info "[Upload Answer Key] File saved, size: #{File.size(temp_path)} bytes"

      # Parse and update answers
      Rails.logger.info "[Upload Answer Key] Starting parse service for stimulus #{@stimulus.id}"
      parser = AnswerKeyParserService.new(temp_path.to_s, @stimulus)
      results = parser.parse_and_update
      Rails.logger.info "[Upload Answer Key] Parse complete: #{results.inspect}"

      # Clean up temp file
      File.delete(temp_path) if File.exist?(temp_path)

      # Recalculate bundle metadata
      @stimulus.recalculate_bundle_metadata!

      if results[:errors].any?
        redirect_to researcher_passage_path(@stimulus),
                    alert: "정답지 처리 중 오류: #{results[:errors].join(', ')}"
      else
        redirect_to researcher_passage_path(@stimulus),
                    notice: "정답지 등록 완료! 객관식 #{results[:mcq_updated]}개, 루브릭 #{results[:rubrics_updated]}개 업데이트"
      end
    rescue => e
      Rails.logger.error "[Upload Answer Key] Error: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to researcher_passage_path(@stimulus),
                  alert: "정답지 처리 중 오류가 발생했습니다: #{e.message}"
    end
  end

  # Bulk update answers for all items in stimulus
  def bulk_update_answers
    answers_params = params[:answers] || {}

    updated_count = 0
    errors = []

    @stimulus.items.each do |item|
      item_params = answers_params[item.id.to_s]
      next unless item_params

      if item.mcq?
        # Update MCQ correct answer
        correct_choice_id = item_params[:correct_choice_id]
        if correct_choice_id.present?
          item.item_choices.update_all(is_correct: false)
          choice = item.item_choices.find_by(id: correct_choice_id)
          if choice
            choice.update(is_correct: true)
            updated_count += 1
          end
        end
      end

      # Update explanation
      if item_params[:explanation].present?
        item.update(explanation: item_params[:explanation])
      end
    end

    # Recalculate bundle metadata
    @stimulus.recalculate_bundle_metadata!

    redirect_to researcher_passage_path(@stimulus),
                notice: "#{updated_count}개 문항의 정답이 업데이트되었습니다."
  end

  # Download answer key template Excel
  def download_answer_template
    service = AnswerKeyTemplateService.new(@stimulus)
    excel_content = service.generate_excel_template

    filename = "정답지_템플릿_#{@stimulus.code}_#{Date.current.strftime('%Y%m%d')}.xlsx"

    send_data excel_content,
              filename: filename,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  # Upload filled answer key template (CSV or Excel)
  def upload_answer_template
    unless params[:answer_template].present?
      redirect_to researcher_passage_path(@stimulus), alert: "파일을 선택해주세요."
      return
    end

    uploaded_file = params[:answer_template]
    filename = uploaded_file.original_filename.downcase

    # Detect file type
    is_excel = filename.end_with?(".xlsx", ".xls") ||
               uploaded_file.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ||
               uploaded_file.content_type == "application/vnd.ms-excel"

    is_csv = filename.end_with?(".csv") ||
             uploaded_file.content_type == "text/csv" ||
             uploaded_file.content_type == "text/plain"

    unless is_excel || is_csv
      redirect_to researcher_passage_path(@stimulus), alert: "Excel(.xlsx) 또는 CSV 파일만 업로드할 수 있습니다."
      return
    end

    begin
      service = AnswerKeyTemplateService.new(@stimulus)

      if is_excel
        # Save to temp file for roo to process (use ASCII-safe filename to avoid encoding issues on Windows)
        ext = File.extname(uploaded_file.original_filename).downcase
        temp_path = Rails.root.join("tmp", "answer_template_#{Time.now.to_i}_#{SecureRandom.hex(4)}#{ext}")
        File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

        results = service.process_excel_template(temp_path.to_s)

        # Clean up
        File.delete(temp_path) if File.exist?(temp_path)
      else
        # CSV processing
        csv_content = uploaded_file.read.force_encoding("UTF-8")
        results = service.process_template(csv_content)
      end

      # Recalculate bundle metadata
      @stimulus.recalculate_bundle_metadata!

      if results[:errors].any?
        redirect_to researcher_passage_path(@stimulus),
                    alert: "일부 항목 처리 중 오류: #{results[:errors].first(3).join(', ')}"
      else
        redirect_to researcher_passage_path(@stimulus),
                    notice: "정답 등록 완료! 객관식 #{results[:mcq_updated]}개, 루브릭 #{results[:rubrics_updated]}개 업데이트"
      end
    rescue => e
      Rails.logger.error "[Upload Answer Template] Error: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to researcher_passage_path(@stimulus),
                  alert: "템플릿 처리 중 오류가 발생했습니다: #{e.message}"
    end
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_stimulus
    @stimulus = ReadingStimulus.includes(items: [:item_choices, :evaluation_indicator, :sub_indicator, rubric: { rubric_criteria: :rubric_levels }]).find(params[:id])
  end

  def stimulus_params
    params.require(:reading_stimulus).permit(:title, :body, :source, :word_count, :reading_level, images: [])
  end

  def sanitize_body(text)
    ActionController::Base.helpers.sanitize(
      text.to_s.strip,
      tags: ApplicationHelper::RICH_TEXT_TAGS,
      attributes: ApplicationHelper::RICH_TEXT_ATTRIBUTES
    )
  end
end
