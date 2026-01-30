class AddLiteracyReportPrompts < ActiveRecord::Migration[8.1]
  def up
    # 진단 개요 및 지표 설명
    FeedbackPrompt.create!(
      title: "진단 개요 및 지표 설명",
      category: "report_overview",
      prompt_text: <<~PROMPT,
        리딩 PRO 문해력 진단 분석을 위한 조사 개요를 다음과 같이 작성하세요:

        1. 진단 목적: 리딩 PRO 문해력 진단은 학생의 전반적인 문해력 수준을 평가하여 강점과 약점을 파악하고자 실시되었습니다.

        2. 평가 지표 및 하위 영역:
        - 이해력: 글의 내용을 정확히 파악하고 추론하는 능력
          * 사실적 이해: 글에 명시된 정보를 있는 그대로 이해
          * 추론적 이해: 글에 나타나지 않은 내용을 근거를 통해 추론
          * 비판적 이해: 글의 내용 및 논리를 평가하고 판단

        - 의사소통 능력: 글을 통해 생각을 표현하고 다른 사람과 상호 작용하는 능력
          * 표현과 전달 능력: 자신의 이해 내용을 말이나 글로 정확히 표현
          * 사회적 상호작용: 읽은 내용을 바탕으로 타인과 소통하고 협력
          * 창의적 문제 해결: 텍스트의 내용을 응용하거나 새로운 해결책을 찾는 능력

        - 심미적 감수성: 문학 작품 등을 감상하며 아름다움이나 의미를 느끼고 공감하는 능력
          * 문학적 표현: 작가의 표현 기법과 언어의 아름다움에 대한 이해
          * 정서적 공감: 등장인물의 감정이나 심리에 공감하는 능력
          * 문학적 가치: 작품이 담고 있는 주제의식이나 교훈을 파악하는 능력

        위 내용을 전문적이고 객관적인 높임체로 작성합니다.
      PROMPT
      is_template: true,
      user_id: 1
    )

    # MCQ 정답 분석
    FeedbackPrompt.create!(
      title: "객관식 정답 분석",
      category: "mcq_correct_analysis",
      prompt_text: <<~PROMPT,
        객관식 문항에서 학생이 정답을 선택한 경우, 다음의 고정 문구를 사용하여 분석하세요:

        "지문을 정확히 이해하고 정답을 선택하였습니다."

        이 분석은 모든 정답에 대해 동일하게 적용됩니다. 해석 및 피드백 항목에 이 문구를 그대로 작성합니다.
      PROMPT
      is_template: true,
      user_id: 1
    )

    # MCQ 오답 분석
    FeedbackPrompt.create!(
      title: "객관식 오답 분석",
      category: "mcq_incorrect_analysis",
      prompt_text: <<~PROMPT,
        객관식 문항에서 학생이 오답을 선택한 경우, 다음 구조로 분석하세요:

        1. 선택된 선지의 오답 이유 파악 (엑셀의 문항별·선지별 해설 참고)
        2. 다음 구조로 작성:
           "이 선택지는 [선지별 오답 해설입니다].
           학생은 [평가 지표(이해력/의사소통능력/심미적감수성), 하위 지표(사실적 이해/추론적 이해/비판적 이해/사회적 상호작용/창의적 문제해결/표현과 전달 능력)]에서 부족한 사고영역 때문에 이 선지를 고른 것으로 보입니다.
           따라서 오답입니다."

        3. 규칙:
           - '왜 오답인지' + '학생이 부족했던 점'을 함께 제시
           - 같은 선지를 고른 학생은 항상 같은 해설 출력
           - 엑셀 파일의 선지별 해설을 반드시 참고하여 작성
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 미응답 분석
    FeedbackPrompt.create!(
      title: "객관식 미응답 분석",
      category: "mcq_no_response_analysis",
      prompt_text: <<~PROMPT,
        객관식 문항에서 학생이 응답을 하지 않은 경우, 다음의 고정 문구를 사용하세요:

        "답안이 존재하지 않아 분석할 수 없습니다."

        모든 미응답 항목에 동일하게 적용됩니다.
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 서술형 문항 분석
    FeedbackPrompt.create!(
      title: "서술형 문항 분석",
      category: "constructed_analysis",
      prompt_text: <<~PROMPT,
        서술형 문항 분석을 다음 기준으로 작성하세요:

        1. 평가: 적절, 부족, 보완필요, 미흡 등으로 평가

        2. 장점 분석:
           - 평가 지표(이해력/의사소통능력/심미적감수성)
           - 하위 지표(사실적 이해/추론적 이해/비판적 이해/사회적 상호작용/창의적 문제해결/표현과 전달 능력)
           - 감정 표현, 문장 구조, 구체성, 중심 생각 파악 등의 기준 반영

        3. 개선점 및 보완 사항:
           - 부족한 영역 명시
           - 구체적인 개선 방향 제시

        4. 종합 피드백:
           - 학생 응답과 정답을 비교하여 장점·보완점·피드백 중심으로 상세히 작성
           - 전문적이고 객관적인 높임체 사용
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 정답률 및 문해력 종합분석
    FeedbackPrompt.create!(
      title: "정답률 분석 및 문해력 종합분석",
      category: "score_analysis",
      prompt_text: <<~PROMPT,
        각 평가 항목별 정답률을 분석하세요:

        1. 평가 지표별 분석:
           - 이해력: 정답률(%), 오답률(%)
           - 의사소통능력: 정답률(%), 오답률(%)
           - 심미적감수성: 정답률(%), 오답률(%)

        2. 하위 지표별 분석:
           - 사실적 이해: 정답률(%), 오답률(%)
           - 추론적 이해: 정답률(%), 오답률(%)
           - 비판적 이해: 정답률(%), 오답률(%)
           - 사회적 상호작용: 정답률(%), 오답률(%)
           - 창의적 문제해결: 정답률(%), 오답률(%)
           - 표현과 전달 능력: 정답률(%), 오답률(%)

        3. 비율 및 분석:
           - 각 항목별 비율 제시 (표 형식)
           - 강점 영역 분석
           - 약점 영역 분석
           - 종합 문해력 수준 평가

        4. 작성 방식:
           - 전문적이고 객관적인 높임체 사용
           - 구체적인 수치와 함께 분석
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 독자 성향 분석
    FeedbackPrompt.create!(
      title: "독자 성향 분석 및 진단",
      category: "reader_tendency_analysis",
      prompt_text: <<~PROMPT,
        독자 성향 데이터를 분석하여 다음을 작성하세요:

        1. 주요 결과 분석:
           - 항목별 평균·비율 포함
           - 세부 지표별 점수 해석
           - 학생의 특징적인 패턴 도출

        2. 종합 진단:
           - 독자 유형 분류 (A~D 유형)
           - 각 유형의 특성 설명
           - 해당 학생의 분류 근거

        3. 독자 성향 해석:
           - 흥미도 분석
           - 자기주도성 분석
           - 가정 지원 수준 분석

        4. 작성 방식:
           - 전문적이고 객관적인 높임체
           - 구체적인 수치 기반 분석
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 독자 성향 교육적 제언
    FeedbackPrompt.create!(
      title: "독자 성향 교육적 제언",
      category: "reader_tendency_guidance",
      prompt_text: <<~PROMPT,
        독자 성향 분석을 바탕으로 교육적 제언을 작성하세요:

        1. 흥미 유발 방안:
           - 학생의 관심 분야 기반 도서 추천
           - 읽기 동기 강화 방법
           - 다양한 장르 소개 및 경험 확대

        2. 자기주도성 강화 방안:
           - 독립적 읽기 학습 전략
           - 자기 점검 및 평가 방법
           - 목표 설정 및 실행 계획

        3. 가정 연계 방안:
           - 부모 참여 방법
           - 가정에서의 읽기 환경 구성
           - 부모-자녀 함께 읽기 프로그램

        4. 작성 방식:
           - 전문적이고 객관적인 높임체
           - 구체적이고 실행 가능한 제안
           - 학생의 특성을 반영한 맞춤형 제언
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 문해력 종합 분석 및 개선점
    FeedbackPrompt.create!(
      title: "문해력 종합 분석 및 개선점",
      category: "comprehensive_literacy_analysis",
      prompt_text: <<~PROMPT,
        앞선 객관식, 서술형, 정답률 분석을 종합하여 상세한 분석을 작성하세요:

        1. 강점 영역:
           - 특히 우수한 능력 명시
           - 높은 정답률을 보인 지표
           - 발휘된 사고의 질

        2. 약점 영역:
           - 개선이 필요한 영역 명시
           - 낮은 정답률을 보인 지표
           - 부족한 사고 능력

        3. 정밀 분석:
           - 각 평가 지표별 심층 분석
           - 하위 지표별 상세한 해석
           - 오류 패턴 분석
           - 학생의 사고 경향성 파악

        4. 개선 전략:
           - 약점 영역의 구체적인 개선 방안
           - 강점 영역의 심화 방안
           - 단계적 발전 방향

        5. 작성 방식:
           - 전문적이고 객관적인 높임체
           - 구체적인 사례 제시
      PROMPT
      is_template: true,
      user_id: 1
    )

    # 문해력 향상을 위한 지도 방향
    FeedbackPrompt.create!(
      title: "문해력 향상을 위한 지도 방향",
      category: "teaching_direction",
      prompt_text: <<~PROMPT,
        각 역량별로 구체적인 지도 방향을 제시하세요:

        1. 이해력 향상 지도:
           - 사실적 이해: 정보 추출 및 명시적 내용 이해 전략
           - 추론적 이해: 근거 기반 추론 능력 강화
           - 비판적 이해: 비판적 사고 및 평가 능력 개발

        2. 의사소통능력 향상 지도:
           - 표현과 전달 능력: 명확한 글쓰기 및 표현력 강화
           - 사회적 상호작용: 협력적 읽기 및 토론 능력
           - 창의적 문제해결: 창의적 사고 및 응용 능력

        3. 심미적 감수성 향상 지도:
           - 문학적 표현: 표현 기법 이해 및 감상 능력
           - 정서적 공감: 감정 및 심리 이해 능력
           - 문학적 가치: 작품의 의미와 가치 파악 능력

        4. 통합 지도 전략:
           - 단계별 학습 계획
           - 활용 가능한 교수 방법
           - 평가 및 피드백 방식

        5. 작성 방식:
           - 전문적이고 객관적인 높임체
           - 구체적이고 실행 가능한 지도 전략
      PROMPT
      is_template: true,
      user_id: 1
    )
  end

  def down
    FeedbackPrompt.where(category: [
      "report_overview",
      "mcq_correct_analysis",
      "mcq_incorrect_analysis",
      "mcq_no_response_analysis",
      "constructed_analysis",
      "score_analysis",
      "reader_tendency_analysis",
      "reader_tendency_guidance",
      "comprehensive_literacy_analysis",
      "teaching_direction"
    ]).destroy_all
  end
end
