# this contains the informations about an evaluation
class Evaluation < ActiveRecord::Base
	# the type of the evaluation
	enum evaluation_type: [ :written, :oral, :pratical ]

	# link to the teacher who created the evaluation
	belongs_to :teacher, :class_name => User
	# link to the student who own the evaluation
	belongs_to :student, :class_name => User
	# the subject of the evaluation
	belongs_to :subject
	# the score of the evaluation
	belongs_to :score
	# the evaluation may be in a class test group
	belongs_to :class_test
end
