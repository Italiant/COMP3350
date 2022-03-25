DROP TABLE AcademicProgram, Staff, OrganisationalUnits, Employees, Student, courseEnrollment, courseOffer, Course, assKnowledge, prereqKnowledge, CourseDetails, MajorMinor, IncludedIn, PhysicalCampus, Facilities, SemesterTrimester, TimeSlot

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
INSERT INTO courseEnrollment VALUES (0000001, 2, '01/01/2020', 49, 'F', 'Completed', 'SENG1110')
INSERT INTO courseEnrollment VALUES (0000001, 3, '01/01/2020', 99, 'P', 'Completed', 'ELEC1120')
INSERT INTO courseEnrollment VALUES (0000001, 4, '01/01/2020', 65, 'P', 'Completed', 'ELEC3350')
INSERT INTO courseEnrollment VALUES (0000001, 5, '01/01/2020', 39, 'F', 'Completed', 'COMP1010')
INSERT INTO courseEnrollment VALUES (0000001, 6, '01/01/2020', null, null, 'Enrolled', 'COMP2010')

INSERT INTO prereqKnowledge VALUES ('ELEC3350', 'ELEC1120')
INSERT INTO prereqKnowledge VALUES ('ELEC3350', 'SENG1110')
INSERT INTO prereqKnowledge VALUES ('COMP2010', 'COMP1010')

INSERT INTO assKnowledge VALUES ('ELEC3350', 'SENG1110')
INSERT INTO CourseDetails VALUES ('ELEC3350', '12345678', '01/01/2020')
INSERT INTO MajorMinor VALUES ('11111111', 'Software', '30', 'software based', '30 units of  directed courses', '12345678')
INSERT INTO IncludedIn VALUES ('ELEC3350', '11111111')
INSERT INTO Facilities VALUES (1, 1, 'Engineering A', 50, 'Classroom', 1)
INSERT INTO TimeSlot VALUES (1, '10:00', 2, 'Tuesday')

CREATE TABLE AcademicProgram
(
	proCode CHAR(8) PRIMARY KEY,
	proName VARCHAR(255) UNIQUE NOT NULL,
	credits TINYINT CHECK (credits BETWEEN 0 AND 200) DEFAULT 20,
	level INT,
	certification VARCHAR(255),
)

CREATE TABLE Staff
(
	stfNo INT CHECK (stfNo BETWEEN 0000000 AND 9999999) PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	street VARCHAR(255),
	city VARCHAR(255),
	postcode INT CHECK (postcode BETWEEN 0000 and 9999),
	telNo BIGINT CHECK (telNo BETWEEN 0000000000 and 9999999999),
	proCode CHAR(8),
	startDate VARCHAR(255),
	endDate VARCHAR(255),
	CONSTRAINT employments FOREIGN KEY(proCode) REFERENCES AcademicProgram(proCode)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE OrganisationalUnits
(
	orgCode INT PRIMARY KEY,
	orgName VARCHAR(255) UNIQUE NOT NULL,
	description VARCHAR(255),
	contact VARCHAR(255)
)

CREATE TABLE Employees
(
	stfNo INT CHECK (stfNo BETWEEN 0000000 AND 9999999),
	orgCode INT,
	position VARCHAR(255),
	startDate VARCHAR(255),
	endDate VARCHAR(255),
	PRIMARY KEY(stfNo, orgCode, position),
	CONSTRAINT stfNo FOREIGN KEY(stfNo) REFERENCES Staff(stfNo)ON UPDATE CASCADE ON DELETE NO ACTION, 
	CONSTRAINT orgCode FOREIGN KEY(orgCode) REFERENCES OrganisationalUnits(orgCode)ON DELETE NO ACTION 
) 

CREATE TABLE Student
(
	stuNo INT PRIMARY KEY CHECK (stuNo BETWEEN 0000000 AND 9999999),
	name VARCHAR(255) NOT NULL,
	street VARCHAR(255),
	city VARCHAR(255),
	postcode INT CHECK (postcode BETWEEN 0000 and 9999),
	telNo BIGINT CHECK (telNo BETWEEN 0000000000 and 9999999999),
	proCode CHAR(8),
	startDate VARCHAR(255),
	completeDate VARCHAR(255),
	status VARCHAR(255),
	CONSTRAINT enrollments FOREIGN KEY(proCode) REFERENCES AcademicProgram(proCode)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE PhysicalCampus
(
	campusID INT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	city VARCHAR(255),
	country VARCHAR(255)
)

CREATE TABLE SemesterTrimester
(
	semID INT PRIMARY KEY, 
	name VARCHAR(255) NOT NULL,
	year SMALLINT CHECK(year BETWEEN 2000 AND 9999)
)

CREATE TABLE Course 
(
	courseID VARCHAR(255) PRIMARY KEY,
	courseName VARCHAR(255) UNIQUE NOT NULL,
	credits TINYINT CHECK (credits BETWEEN 0 AND 200) DEFAULT 20,
	description VARCHAR(255),
)

CREATE TABLE courseOffer
(
	offerID INT PRIMARY KEY,
	campusID INT REFERENCES PhysicalCampus(campusID),
	semID INT REFERENCES SemesterTrimester ON UPDATE CASCADE ON DELETE NO ACTION,
	stfNo INT,
	courseName VARCHAR(255),
	FOREIGN KEY(courseName) REFERENCES Course(courseName) ON UPDATE CASCADE ON DELETE NO ACTION,
	CONSTRAINT courseCoordinator FOREIGN KEY(stfNo) REFERENCES Staff(stfNo) ON UPDATE CASCADE ON DELETE NO ACTION
)

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

CREATE TABLE prereqKnowledge
(
	courseName VARCHAR(255),
	preCourse VARCHAR(255), 
	CONSTRAINT preCourseID FOREIGN KEY(courseName) REFERENCES Course(courseName)ON DELETE NO ACTION,
	CONSTRAINT preCourse FOREIGN KEY(preCourse) REFERENCES Course(courseName)ON DELETE NO ACTION 
) 

CREATE TABLE assKnowledge
(
	courseName VARCHAR(255) PRIMARY KEY,
	assCourse VARCHAR(255),
	CONSTRAINT assCourseID FOREIGN KEY(courseName) REFERENCES Course(courseName)ON DELETE NO ACTION,
	CONSTRAINT assCourse FOREIGN KEY(assCourse) REFERENCES Course(courseName)ON DELETE NO ACTION  
)

CREATE TABLE CourseDetails
(
	courseName VARCHAR(255),
	proCode CHAR(8),
	startDate VARCHAR(255),
	PRIMARY KEY(courseName, proCode, startDate),
	CONSTRAINT courseID FOREIGN KEY(courseName) REFERENCES Course(courseName)ON UPDATE CASCADE ON DELETE NO ACTION,
	CONSTRAINT proCode FOREIGN KEY(proCode) REFERENCES AcademicProgram(proCode)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE MajorMinor
(
	majCode CHAR(8) PRIMARY KEY, 
	majName VARCHAR(255) UNIQUE NOT NULL,
	credits TINYINT CHECK (credits BETWEEN 0 AND 200) DEFAULT 20,
	description VARCHAR(255), 
	conditions VARCHAR(255), 
	proCode CHAR(8),
	CONSTRAINT parentProgram FOREIGN KEY(proCode) REFERENCES AcademicProgram(proCode)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE IncludedIn
(
	courseName VARCHAR(255),
	majCode CHAR(8),
	PRIMARY KEY(courseName, majCode),
	CONSTRAINT cID FOREIGN KEY(courseName) REFERENCES Course(courseName)ON UPDATE CASCADE ON DELETE NO ACTION,
	CONSTRAINT mCode FOREIGN KEY(majCode) REFERENCES MajorMinor(majCode)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE Facilities
(
	facID INT PRIMARY KEY,
	roomNo INT NOT NULL,
	building VARCHAR(255),
	capacity INT,
	type VARCHAR(255),
	campusID INT,
	CONSTRAINT comprisedOf FOREIGN KEY(campusID) REFERENCES PhysicalCampus(campusID)ON UPDATE CASCADE ON DELETE NO ACTION
)

CREATE TABLE TimeSlot
(
	offerID INT NOT NULL,
	time VARCHAR(255), 
	length INT, 
	day VARCHAR(255),
	CONSTRAINT oID FOREIGN KEY(offerID) REFERENCES CourseOffer(offerID)ON UPDATE CASCADE ON DELETE NO ACTION
)