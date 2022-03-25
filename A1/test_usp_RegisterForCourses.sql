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

-------------------------------------------------------------------------------------------------------------------------------------------------------

DROP PROCEDURE usp_RegisterForCourses
DROP TYPE courseOfferingList

-- Create a type called "courseOfferingList" as a table to hold a table-valued parameter that has the list of course offers
CREATE TYPE courseOfferingList AS TABLE
(
	courseOfferingIds INT PRIMARY KEY
)
GO

-- STORED PROCEDURE: usp_RegisterForCourses
-- STEPS:
--	(1) Inputs require a valid student number (INT) and a valid table-valued parameter from the type "courseOfferingList" as a table
--	(2) Declare a cursor to search through each row in the course offer table and store each offerID and course name in seperate private variables
--	(3) Where the offerID from the course offer table matches an entered offerID from the input table then save the ID to a private variable
--	(4) Do the same as (3) but for course name and use the offerID found in (3) to match to an offerID from the course offer table
--	(5) If the offerID from (3) matches the offerID in the row that the cursor is currently on then begin try-catch block to insert into the courseEnrollment table i.e. enroll the student into that course from the course offer
--	(6) Catch and handle errors for 4 different different error cases, including 2 custom defined errors raised in the trigger
--	(7) Move the cursor forward a row and finally close and deallocate it

CREATE PROCEDURE usp_RegisterForCourses @studentNumber INT, @courseOffers courseOfferingList READONLY
AS
Begin

	DECLARE @countOffers INT
	SET @countOffers = 0

	Select @countOffers = COUNT(*)
	FROM @courseOffers

	PRINT @countOffers

	DECLARE procCursor CURSOR
	FOR
	SELECT offerID, courseName
	FROM courseOffer
	FOR READ ONLY

	DECLARE @offerID INT, 
			@offerID_t INT,
			@courseName VARCHAR(255),
			@courseName_t VARCHAR(255)

	OPEN procCursor

	FETCH NEXT FROM procCursor INTO @offerID, @courseName

	WHILE @@FETCH_STATUS= 0
	BEGIN		
		SET @offerID_t = (SELECT courseOfferingIds FROM @courseOffers o WHERE @offerID = o.courseOfferingIds)  
		PRINT 'offerID = ' + CAST(@offerID_t AS CHAR)

		SET @courseName_t = (SELECT courseName FROM courseOffer c WHERE @offerID_t = c.offerID)  
		PRINT 'courseName = ' + CAST(@courseName_t AS VARCHAR)

		IF(@offerID_t = @offerID)
		BEGIN
			BEGIN TRY
				INSERT INTO courseEnrollment VALUES (@studentNumber, @offerID_t, '01/01/2020', null, null, 'Enrolled', @courseName_t)
			END TRY

			BEGIN CATCH
				SELECT ERROR_NUMBER() AS ErrorNumber
				SELECT ERROR_MESSAGE() AS ErrorMessage 

				IF(ERROR_NUMBER() = 2627) --2627 = Violation of Primary key constraint = duplicate
					RAISERROR ('A duplicate course cannot be added.', 15, 1)
				
				IF(ERROR_NUMBER() = 3609) --3609 = ended in the trigger
					RAISERROR ('Error occured in the trigger', 15, 1)
				
				IF(ERROR_NUMBER() = 50005)
					RAISERROR ('The Student has not completed all of the prerequisite courses', 15, 1)

				IF(ERROR_NUMBER() = 50006)
					RAISERROR ('The Student has not acquired a passing grade in the prerequisite course(s)', 15, 1)
			END CATCH
		END

		FETCH NEXT FROM procCursor INTO @offerID, @courseName
	END

	CLOSE procCursor
	DEALLOCATE procCursor 
END

DECLARE @oList courseOfferingList

INSERT INTO @oList VALUES (5)
INSERT INTO @oList VALUES (7)
INSERT INTO @oList VALUES (1)

EXECUTE usp_RegisterForCourses 1, @oList
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO AcademicProgram VALUES ('12345678', 'Computer Systems Engineering', 200, 4, 'Bachelor')
INSERT INTO Staff VALUES (1, 'Obi-wan Kenobi', 'Jawa St', 'Tatooine', 4000, 0000000001, '12345678', '01/01/2020', null)
INSERT INTO OrganisationalUnits VALUES (1, 'Engineering', 'Nerds build stuff', 'engineering@uon.edu.au')
INSERT INTO Employees VALUES (1, 1, 'Master', '01/01/2020', null)
INSERT INTO Student VALUES (0000001, 'Luke Skywalker', 'Wookie St', 'Kashyyyk', 4001, 0000000002, '12345678', '01/01/2020', null, 'enrolled')
INSERT INTO Student VALUES (0000002, 'Leia Organa', ' Polis Massa St', 'Alderaan', 1935, 0000000005, '12345679', '19/01/2020', null, 'enrolled')
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

INSERT INTO courseEnrollment VALUES (0000001, 2, '01/01/2020', 49, 'F', 'Completed', 'SENG1110')

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