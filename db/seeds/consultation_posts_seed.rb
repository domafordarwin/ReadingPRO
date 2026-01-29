# frozen_string_literal: true

puts "Creating consultation posts seed data..."

# 학생 및 교사 사용자 찾기
student_user = User.find_by(role: 'student')
teacher_user = User.find_by(role: 'diagnostic_teacher')
student = Student.first

unless student_user && teacher_user && student
  puts "Skipping consultation posts seed: Required users or students not found"
  return
end

# 시나리오 1: 비공개 - 진단 결과 이해 질문
post1 = ConsultationPost.create!(
  student: student,
  created_by: student_user,
  title: "3번 문항 채점 결과가 이해가 안 가요",
  content: <<~CONTENT
    안녕하세요. 이번 진단에서 3번 서술형 문항을 작성했는데,
    채점 결과를 보니 '내용 전개' 부분에서 점수가 낮게 나왔습니다.

    제 답변에서 어떤 부분이 부족했는지 구체적으로 설명해주실 수 있을까요?
    다음에는 어떻게 답변해야 더 좋은 점수를 받을 수 있을지 궁금합니다.
  CONTENT
  category: 'assessment',
  visibility: 'private',
  status: 'open',
  views_count: 5
)

ConsultationComment.create!(
  consultation_post: post1,
  created_by: teacher_user,
  content: <<~CONTENT
    안녕하세요. 3번 문항 채점 결과에 대해 질문해주셨네요.

    해당 문항에서는 주어진 지문을 읽고 핵심 내용을 논리적으로 설명하는 능력을 평가합니다.
    학생의 답변을 보면 지문의 핵심은 잘 파악했지만, 내용을 전개하는 과정에서
    문장 간 연결이 자연스럽지 않고, 근거가 부족한 부분이 있었습니다.

    다음번에는:
    1. 주장 → 근거 → 예시 순서로 구조화하여 작성해보세요
    2. 접속사를 활용하여 문장 간 관계를 명확히 하세요
    3. 지문의 구체적인 부분을 인용하여 근거를 보강하세요

    추가 질문이 있으면 언제든 물어보세요!
  CONTENT
)

# 시나리오 2: 공개 - 학습 팁 공유
post2 = ConsultationPost.create!(
  student: student,
  created_by: student_user,
  title: "서술형 문항 답변 작성 팁 공유합니다!",
  content: <<~CONTENT
    안녕하세요! 저번 진단에서 서술형 문항 점수를 많이 올렸는데,
    제가 사용한 방법을 공유하려고 합니다.

    1. 답변 작성 전에 30초 정도 생각하며 구조를 잡기
    2. 주장 - 근거 - 결론 순서로 작성하기
    3. 지문에서 관련 내용 찾아서 활용하기

    다들 도움이 되셨으면 좋겠어요!
  CONTENT
  category: 'learning',
  visibility: 'public',
  status: 'answered',
  views_count: 42
)

ConsultationComment.create!(
  consultation_post: post2,
  created_by: teacher_user,
  content: <<~CONTENT
    좋은 학습 팁을 공유해주셔서 감사합니다!

    특히 답변 작성 전 구조를 먼저 생각하는 것은 매우 중요한 전략입니다.
    여기에 추가로, 시간 배분도 중요한데요:

    - 지문 읽기: 3분
    - 문제 이해 및 구조 잡기: 1분
    - 답변 작성: 5분
    - 검토: 1분

    이렇게 시간을 나누어 연습해보세요.
    다른 친구들도 참고하면 좋을 것 같네요!
  CONTENT
)

# 시나리오 3: 비공개 - 개인적 어려움
post3 = ConsultationPost.create!(
  student: student,
  created_by: student_user,
  title: "독해 속도가 너무 느려서 고민입니다",
  content: <<~CONTENT
    선생님, 저는 진단 시험을 볼 때마다 시간이 부족합니다.
    다른 친구들은 다 풀고 검토까지 하는데, 저는 지문을 읽는 것만으로도
    시간이 많이 걸려서 마지막 문제까지 못 풀 때가 많아요.

    집에서 독해 연습을 하려고 하는데, 어떻게 하면 좋을까요?
    속도를 높이면서도 정확하게 읽는 방법이 궁금합니다.
  CONTENT
  category: 'personal',
  visibility: 'private',
  status: 'answered',
  views_count: 3
)

ConsultationComment.create!(
  consultation_post: post3,
  created_by: teacher_user,
  content: <<~CONTENT
    독해 속도에 대한 고민을 이야기해주셨네요.
    이것은 많은 학생들이 겪는 어려움이에요.

    단계별로 연습해보세요:

    **1단계 (현재 수준):**
    - 짧은 글(200-300자)부터 시작
    - 정확도 80% 이상 유지하면서 읽기
    - 타이머로 시간 재기

    **2단계 (2주 후):**
    - 글 길이 늘리기 (400-500자)
    - 핵심 내용 요약하는 연습

    **3단계 (4주 후):**
    - 시험 수준의 지문으로 연습
    - 문제 풀이 포함

    매일 15분씩만 꾸준히 하면 분명히 개선됩니다.
    한 달 후에 다시 이야기 나눠보면 좋겠어요!
  CONTENT
)

# 추가 샘플 게시글들
5.times do |i|
  post = ConsultationPost.create!(
    student: student,
    created_by: student_user,
    title: "질문 #{i + 4}: 읽기 전략 관련 문의",
    content: "이 부분이 궁금합니다. 자세한 설명 부탁드립니다.",
    category: ['assessment', 'learning', 'technical'].sample,
    visibility: ['private', 'public'].sample,
    status: ['open', 'answered'].sample,
    views_count: rand(1..30)
  )

  if post.answered?
    ConsultationComment.create!(
      consultation_post: post,
      created_by: teacher_user,
      content: "좋은 질문입니다. 자세한 설명을 드리겠습니다."
    )
  end
end

puts "Created #{ConsultationPost.count} consultation posts"
puts "Created #{ConsultationComment.count} consultation comments"
