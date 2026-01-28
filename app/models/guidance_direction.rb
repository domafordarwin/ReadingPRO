class GuidanceDirection < ApplicationRecord
  belongs_to :attempt
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true
end
