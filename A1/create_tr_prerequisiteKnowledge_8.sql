--DROP TRIGGER checkBuisnessRule

-- TRIGGER: checkBuisnessRule
-- STEPS:
--	(1) Find the number of prerequsite knowledge courses for the course to be enrolled in
--	(2) Search through the course enrollment table and count the number of courses which match the prerequsite knowledge courses for the course the student is enrolling into
--	(3) In the same table count the number of courses for the same condition where the grade is a “F” (fail) or null and the status is not “completed”
--	(4) If steps (1) and (2) are not equal and there is at least one prerequsite knowledge course for the course or if (3) is greater than zero then raise error 
--	(5) Rollback transation

CREATE TRIGGER checkBuisnessRule
ON courseEnrollment
FOR UPDATE, INSERT
AS
BEGIN
	DECLARE @countPreCourses INT
	DECLARE @countCourses INT
	DECLARE @countFail INT
	SET @countPreCourses = 0
	SET @countCourses = 0
	SET @countFail = 0

	SELECT @countPreCourses = COUNT(*)
	FROM Inserted i, prereqKnowledge p
	WHERE i.courseName = p.courseName

	SELECT @countCourses = COUNT(*)
	FROM Inserted i, courseEnrollment e, prereqKnowledge p
	WHERE i.stuNo = e.stuNo AND p.courseName = i.courseName AND p.preCourse = e.courseName	

	SELECT @countFail = COUNT(*)
	FROM Inserted i, courseEnrollment e, prereqKnowledge p
	WHERE i.stuNo = e.stuNo AND p.courseName = i.courseName AND p.preCourse = e.courseName AND (e.finalGrade = 'F' OR e.finalGrade = null OR e.status <> 'Completed')

	IF @countCourses <> @countPreCourses AND @countPreCourses <> 0 OR @countFail > 0
	BEGIN
		IF(@countPreCourses <> @countCourses AND @countPreCourses <> 0)
		BEGIN
			EXEC sp_addmessage @msgnum = 50005, @severity = 15, @msgtext = 'The Student has not completed all of the prerequisite courses'
			RAISERROR (50005, 15, 1)
		END

		IF(@countFail > 0)
		BEGIN
			EXEC sp_addmessage @msgnum = 50006, @severity = 15, @msgtext = 'The Student has not acquired a passing grade in the prerequisite course(s)'
			RAISERROR (50006, 15, 1)
		END

		ROLLBACK TRANSACTION
	END
END