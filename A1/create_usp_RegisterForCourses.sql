--DROP PROCEDURE usp_RegisterForCourses
--DROP TYPE courseOfferingList

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
BEGIN
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