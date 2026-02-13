# frozen_string_literal: true

# 문항 128, 133, 135의 prompt HTML 정리 및 누락된 루브릭 생성
# - PDF 파싱 시 삽입된 bogi-box/table 등 HTML 태그 제거
# - 서술형 문항에 누락된 루브릭 생성 (133, 135)
class FixItem133PromptAndRubric < ActiveRecord::Migration[8.0]
  def up
    fix_item_133
    fix_item_128
    fix_item_135
  end

  def down
    # 루브릭만 rollback (prompt 원본 복원은 불가)
    item133 = Item.find_by(code: "4D1457AE_ITEM_S007")
    Rubric.find_by(item_id: item133&.id, name: "편지글 작성 능력 평가")&.destroy

    item135 = Item.find_by(code: "C6DA322E_ITEM_S009")
    Rubric.find_by(item_id: item135&.id, name: "토론 논증 능력 평가")&.destroy
  end

  private

  # === Item 133 (4D1457AE_ITEM_S007): bogi-box HTML + 루브릭 누락 ===
  def fix_item_133
    item = Item.find_by(code: "4D1457AE_ITEM_S007")
    return unless item

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

    return if Rubric.exists?(item_id: item.id)

    create_rubric(item, "편지글 작성 능력 평가", [
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
    ])
  end

  # === Item 128 (DA71BB19_ITEM_S002): bogi-box HTML (루브릭은 있음) ===
  def fix_item_128
    item = Item.find_by(code: "DA71BB19_ITEM_S002")
    return unless item

    clean_prompt = "〈보기〉에서 마을 사람들에게 가장 필요한 조언을 말한 철학자 한 명을 고르고, 그렇게 생각한 이유를 서술하시오.\n\n〈보기〉\n(가) 소크라테스(Socrates): \"알고 있다는 것을 아는 것이 진정한 지혜이다.\"\n소크라테스는 그의 연설 『변론』(Apology)에서 자신이 '무엇을 모른다고 아는 것'이 진정한 지혜라고 주장했다. 또한 그는 사람들이 자만하지 않고, 끊임없이 질문하고 성찰함으로써 더 깊은 진리를 추구해야 한다고 말했다.\n\n(나) 아리스토텔레스(Aristotle): \"도덕적 미덕은 중용에 있다.\"\n아리스토텔레스는 그의 저서 『니코마코스 윤리학』(Nicomachean Ethics)에서 중용의 덕을 강조했다. 그는 인간이 지나치지도, 부족하지도 않은 적당한 균형을 이루는 삶을 살아야 한다고 말하며, 중용이 행복과 도덕적 삶의 핵심이라고 주장하였다.\n\n(다) 헤라클레이토스(Heraclitus): \"모든 것은 흐른다.\"\n헤라클레이토스는 『자연에 관한 말』(Fragments)에서 세상은 끊임없이 변하고 변화하는 것만이 불변이라고 주장하며, 변화 속에서 적응하는 것이 중요하다고 강조하였다."

    item.update_column(:prompt, clean_prompt)
  end

  # === Item 135 (C6DA322E_ITEM_S009): table HTML + 루브릭 누락 ===
  def fix_item_135
    item = Item.find_by(code: "C6DA322E_ITEM_S009")
    return unless item

    clean_prompt = "아래 자료를 활용하여 위의 토론에 참여한다면, 찬성측 또는 반대측 어느 쪽에서 토론할 수 있는지 쓰고, 어떤 측면에서 그러한지 명확히 근거를 들어 서술하시오.\n\n[자료]\n  지표                          1인 배달 자주 이용 집단   권장/전체 평균\n  나트륨 섭취량 (배수)            1.7배                  1.0배(권장량)\n  포화지방 섭취량 (배수)          1.5배                  1.0배(권장량)\n  고열량·고지방 메뉴 비율 (%)     65%                    -\n  채소·과일 메뉴 비율 (%)         8%                     -\n  BMI ≥ 25 비율 (%)             42%                    29%"

    item.update_column(:prompt, clean_prompt)

    return if Rubric.exists?(item_id: item.id)

    create_rubric(item, "토론 논증 능력 평가", [
      {
        name: "입장 선택과 근거의 타당성", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "찬성 또는 반대 입장을 밝혔으나, 자료와 무관한 근거를 제시하거나 근거가 없음."],
          [2, 2, "입장을 밝히고 자료를 일부 활용하였으나, 논리적 연결이 부족하거나 근거가 불충분함."],
          [3, 3, "입장을 명확히 밝히고, 자료의 수치를 구체적으로 활용하여 타당한 근거를 제시함."]
        ]
      },
      {
        name: "자료 활용의 적절성", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "자료의 수치를 전혀 활용하지 않거나, 잘못 해석하여 인용함."],
          [2, 2, "자료의 수치를 일부 인용하였으나, 해석이 부분적이거나 피상적임."],
          [3, 3, "자료의 수치를 정확히 인용하고, 주장을 뒷받침하는 데 효과적으로 활용함."]
        ]
      },
      {
        name: "논리적 표현력", max_score: 4,
        levels: [
          [0, 0, "답안을 제출하지 않음"],
          [1, 1, "문장이 비논리적이거나 표현이 불명확하여 주장을 이해하기 어려움."],
          [2, 2, "전반적으로 이해 가능하나, 논증 구조가 다소 불완전하거나 어휘 선택이 부적절함."],
          [3, 3, "논리적 구조로 서술하고, 적절한 어휘와 표현으로 주장을 명확히 전달함."]
        ]
      }
    ])
  end

  def create_rubric(item, rubric_name, criteria_data)
    rubric = Rubric.create!(item_id: item.id, name: rubric_name)

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
end
