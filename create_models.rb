models = {
  'User' => [ 'Student has_one', 'Teacher has_many items', 'Parent' ],
  'School' => [ 'Student belongs_to', 'Teacher belongs_to' ],
  'Student' => [ 'User belongs_to', 'School belongs_to', 'StudentAttempt has_many', 'StudentPortfolio has_one' ],
  'Teacher' => [ 'User belongs_to', 'School belongs_to', 'Item has_many' ],
  'Parent' => [ 'User belongs_to' ],
  'ReadingStimulus' => [ 'Item has_many' ],
  'Item' => [ 'ReadingStimulus belongs_to', 'Rubric has_one', 'ItemChoice has_many', 'DiagnosticFormItem has_many', 'Response has_many', 'Teacher belongs_to' ],
  'ItemChoice' => [ 'Item belongs_to', 'Response has_many' ],
  'Rubric' => [ 'Item belongs_to', 'RubricCriterion has_many' ],
  'RubricCriterion' => [ 'Rubric belongs_to', 'RubricLevel has_many' ],
  'RubricLevel' => [ 'RubricCriterion belongs_to' ],
  'DiagnosticForm' => [ 'DiagnosticFormItem has_many', 'StudentAttempt has_many', 'Teacher belongs_to' ],
  'DiagnosticFormItem' => [ 'DiagnosticForm belongs_to', 'Item belongs_to' ],
  'StudentAttempt' => [ 'Student belongs_to', 'DiagnosticForm belongs_to', 'Response has_many', 'AttemptReport has_one' ],
  'Response' => [ 'StudentAttempt belongs_to', 'Item belongs_to', 'ItemChoice belongs_to', 'Feedback belongs_to', 'ResponseRubricScore has_many' ],
  'Feedback' => [ 'Response belongs_to', 'Teacher belongs_to' ],
  'ResponseRubricScore' => [ 'Response belongs_to', 'RubricCriterion belongs_to', 'Teacher belongs_to' ],
  'StudentPortfolio' => [ 'Student belongs_to' ],
  'SchoolPortfolio' => [ 'School belongs_to' ],
  'AttemptReport' => [ 'StudentAttempt belongs_to' ],
  'Announcement' => [ 'Teacher belongs_to' ]
}

models.each do |model_name, _relations|
  filename = "app/models/#{model_name.underscore}.rb"
  File.write(filename, "# frozen_string_literal: true\n\nclass #{model_name} < ApplicationRecord\nend\n")
  puts "Created #{filename}"
end

puts "✅ All #{models.size} models created"
