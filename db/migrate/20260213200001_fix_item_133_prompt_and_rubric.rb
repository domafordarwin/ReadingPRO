# frozen_string_literal: true

# 문항 133 (4D1457AE_ITEM_S007) 데이터 수정:
# 1. prompt에 포함된 bogi-box HTML 태그 제거 → 순수 텍스트로 변환
# 2. 누락된 서술형 루브릭 생성 (3개 평가 기준, 각 4수준)
class FixItem133PromptAndRubric < ActiveRecord::Migration[8.0]
  def up
    item = Item.find_by(code: "4D1457AE_ITEM_S007")
    return unless item

    # 1. prompt HTML 정리
    clean_prompt = <<~PROMPT.strip
      다음 글에서 할아버지의 마지막 말에 공감한 소년이 시 (나)의 꽃게에게 전하고 싶은 마음을 편지글의 형식으로 쓰시오. (글자 수 150자 내외)

      [보기]
      할아버지의 얼굴에 처음으로 활짝 웃음꽃이 피었습니다. 소년은 할아버지의 얼굴이 참으로 보기 좋다고 생각했습니다.

      "그런데 왜 시가 쓸모없는 취급을 받았을까요?"
      "무엇에 쓸모 있느냐가 문제였지. 그 시절 사람들은 몸을 잘 살게 하는데 쓸모 있는 것만 중요하게 생각하고 마음을 잘 살게 하는 데 쓸모 있는 건 무시하려 들었으니까."

      "그럼 몸이 잘 사는 것과 마음이 잘 사는 것은 서로 다른 건가요?"
      "암, 다르고말고. 몸이 잘 산다는 건 편안한 것에 길들여지는 거고, 마음이 잘 산다는 건 편안한 것으로부터 놓여나 새로워지는 거고. 몸이 잘 살게 된다는 건 누구나 비슷하게 사는 거지만, 마음이 잘 살게 된다는 건 제각기 제 나름으로 살게 되는 거니까."

      -박완서, 시인의 꿈 중에서-
    PROMPT

    item.update_column(:prompt, clean_prompt)

    # 2. 루브릭 생성 (없는 경우만)
    return if Rubric.exists?(item_id: item.id)

    rubric = Rubric.create!(item_id: item.id, name: "편지글 작성 능력 평가")

    criteria_data = [
      {
        name: "내용의 적절성", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "할아버지의 말과 꽃게에 대한 연결이 부적절하거나, 편지글의 내용이 주제와 무관함."],
          [2, 2, "할아버지의 말을 부분적으로 반영하였으나, 꽃게에게 전하는 마음의 표현이 구체적이지 않음."],
          [3, 3, "할아버지의 말에 공감하여 꽃게에게 전하고 싶은 마음을 적절하고 구체적으로 표현함."]
        ]
      },
      {
        name: "형식과 표현", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "편지글 형식을 갖추지 못하거나, 문장 표현이 매우 부자연스러움."],
          [2, 2, "편지글 형식을 대체로 갖추었으나, 문장 구성이나 어휘 사용이 다소 어색함."],
          [3, 3, "편지글 형식에 맞게 작성하고, 문장 표현이 자연스럽고 정서적으로 적절함."]
        ]
      },
      {
        name: "분량 적합성", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "분량이 지나치게 부족하거나(50자 미만) 초과하여(250자 이상) 과제 조건에 부합하지 않음."],
          [2, 2, "분량이 다소 부족하거나 초과하나, 주요 내용은 포함하고 있음."],
          [3, 3, "150자 내외의 적절한 분량으로 과제 조건에 부합함."]
        ]
      }
    ]

    criteria_data.each do |cd|
      criterion = RubricCriterion.create!(
        rubric_id: rubric.id,
        criterion_name: cd[:name],
        max_score: cd[:max_score]
      )
      cd[:levels].each do |level, score, desc|
        RubricLevel.create!(
          rubric_criterion_id: criterion.id,
          level: level,
          score: score,
          description: desc
        )
      end
    end
  end

  def down
    item = Item.find_by(code: "4D1457AE_ITEM_S007")
    return unless item

    rubric = Rubric.find_by(item_id: item.id, name: "편지글 작성 능력 평가")
    rubric&.destroy
  end
end
