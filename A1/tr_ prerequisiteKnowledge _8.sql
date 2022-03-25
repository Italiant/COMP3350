DROP TRIGGER checkBuisnessRule

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

	SELECT *
	FROM inserted

	SELECT @countPreCourses = COUNT(*)
	FROM Inserted i, prereqKnowledge p
	WHERE i.courseName = p.courseName

	PRINT @countPreCourses

	SELECT @countCourses = COUNT(*)
	FROM Inserted i, courseEnrollment e, prereqKnowledge p
	WHERE i.stuNo = e.stuNo AND p.courseName = i.courseName AND p.preCourse = e.courseName

	PRINT @countCourses	

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO AcademicProgram VALUES ('12345678', 'Computer Systems Engineering', 200, 4, 'Bachelor')
INSERT INTO Staff VALUES (1, 'Obi-wan Kenobi', 'Jawa St', 'Tatooine', 4000, 0000000001, '12345678', '01/01/2020', null)
INSERT INTO OrganisationalUnits VALUES (1, 'Engineering', 'Nerds build stuff', 'engineering@uon.edu.au')
INSERT INTO Employees VALUES (1, 1, 'Master', '01/01/2020', null)
INSERT INTO Student VALUES (0000001, 'Luke Skywalker', 'Wookie St', 'Kashyyyk', 4001, 0000000002, '12345678', '01/01/2020', null, 'enrolled')
INSERT INTO Student VALUES (0000002, 'Leia Organa', ' Polis Massa St', 'Alderaan', 1935, 0000000005, '12345678', '19/01/2020', null, 'enrolled')
INSERT INTO PhysicalCampus VALUES (1, 'Callaghan', 'Newcastle', 'Australia')
INSERT INTO SemesterTrimester VALUES (1, '1', '2020')

INSERT INTO Course VALUES (1, 'ELEC3350', 10, 'Advanced Databases')
INSERT INTO Course VALUES (2, 'ELEC1120', 10, 'Advanced Databases2')
INSERT INTO Course VALUES (3, 'SENG1110', 10, 'Advanced Databases3')
INSERT INTO Course VALUES (4, 'ELEC1000', 10, 'elec1')
INSERT INTO Course VALUES (5, 'COMP1010', 10, 'comp1')
INSERT INTO Course VALUES (6, 'COMP2010', 10, 'comp2')

INSERT INTO courseOffer VALUES (1, 1, 1, 1, 'ELEC1000')
INSERT INTO courseOffer VALUES (2, 1, 1, 1, 'SENG1110')
INSERT INTO courseOffer VALUES (3, 1, 1, 1, 'ELEC1120')
INSERT INTO courseOffer VALUES (4, 1, 1, 1, 'ELEC3350')
INSERT INTO courseOffer VALUES (5, 1, 1, 1, 'ELEC3350')
INSERT INTO courseOffer VALUES (6, 1, 1, 1, 'COMP1010')
INSERT INTO courseOffer VALUES (7, 1, 1, 1, 'COMP2010')

INSERT INTO courseEnrollment VALUES (0000001, 1, '01/01/2020', 68, 'P', 'Completed', 'ELEC1000')

-- Test: The Student has not completed all of the prerequisite courses

INSERT INTO courseEnrollment VALUES (0000001, 2, '01/01/2020', 65, 'P', 'Completed', 'SENG1110')

INSERT INTO courseEnrollment VALUES (0000001, 3, '01/01/2020', 99, 'P', 'Completed', 'ELEC1120')

INSERT INTO courseEnrollment VALUES (0000001, 4, '01/01/2020', 65, 'P', 'Completed', 'ELEC3350')

-- Test: The Student has not acquired a passing grade in the prerequisite course(s)

INSERT INTO courseEnrollment VALUES (0000001, 5, '01/01/2020', 39, 'F', 'Completed', 'COMP1010')

INSERT INTO courseEnrollment VALUES (0000001, 6, '01/01/2020', null, null, 'Enrolled', 'COMP2010')

SELECT * 
FROM courseEnrollment

DROP TABLE courseEnrollment

CREATE TABLE courseEnrollment
(
	stuNo INT CHECK (stuNo BETWEEN 0000000 AND 9999999),
	offerID INT,
	startDate VARCHAR(255),
	finalMark DECIMAL(4,2),
	finalGrade CHAR(1),
	status VARCHAR(255) DEFAULT 'unenrolled',
	courseName VARCHAR(255) NOT NULL,
	PRIMARY KEY (offerID, startDate),
	CONSTRAINT containingC FOREIGN KEY(courseName) REFERENCES Course(courseName)ON UPDATE CASCADE ON DELETE NO ACTION,
	CONSTRAINT stuNo FOREIGN KEY(stuNo) REFERENCES Student(stuNo)ON UPDATE CASCADE ON DELETE NO ACTION,
	FOREIGN KEY(offerID) REFERENCES courseOffer(offerID)ON DELETE NO ACTION
)

DROP TABLE prereqKnowledge

CREATE TABLE prereqKnowledge
(
	courseName VARCHAR(255),
	preCourse VARCHAR(255), 
	CONSTRAINT preCourseID FOREIGN KEY(courseName) REFERENCES Course(courseName)ON DELETE NO ACTION,
	CONSTRAINT preCourse FOREIGN KEY(preCourse) REFERENCES Course(courseName)ON DELETE NO ACTION 
) 

SELECT *
FROM prereqKnowledge

INSERT INTO prereqKnowledge VALUES ('ELEC3350', 'ELEC1120')
INSERT INTO prereqKnowledge VALUES ('ELEC3350', 'SENG1110')
INSERT INTO prereqKnowledge VALUES ('COMP2010', 'COMP1010')

INSERT INTO assKnowledge VALUES ('ELEC3350', 'SENG1110')
INSERT INTO CourseDetails VALUES ('ELEC3350', '12345678', '01/01/2020')
INSERT INTO MajorMinor VALUES ('11111111', 'Software', '30', 'software based', '30 units of  directed courses', '12345678')
INSERT INTO IncludedIn VALUES ('ELEC3350', '11111111')
INSERT INTO Facilities VALUES (1, 1, 'Engineering A', 50, 'Classroom', 1)
INSERT INTO TimeSlot VALUES (1, '10:00', 2, 'Tuesday')