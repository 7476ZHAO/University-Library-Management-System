-- DROP tables (reset database)
DROP TABLE IF EXISTS Fines CASCADE;
DROP TABLE IF EXISTS Loans CASCADE;
DROP TABLE IF EXISTS Librarians CASCADE;
DROP TABLE IF EXISTS Students CASCADE;
DROP TABLE IF EXISTS Books CASCADE;

--1. Create tables
CREATE TABLE Students (
Student_ID Serial Primary Key,
Name Text NOT NULL, 
Major Text NOT NULL,
Email Text UNIQUE NOT NULL,
YearOfStudy Int NOT NULL  --from first year to fourth year
);
------------------------------------------------------------
CREATE TABLE Books(
Book_ID Serial Primary Key,
Title Text NOT NULL,
Author Text NOT NULL,
Category Text  NOT NULL,
YearOfPublication Int NOT NULL
);
-------------------------------------------------------------
CREATE TABLE Librarians(
Librarian_ID Serial Primary Key,
Name Text NOT NULL,
Email Text UNIQUE NOT NULL,
Shift Text NOT NULL
);
--------------------------------------------------------------
CREATE TABLE Loans(
Loan_ID Serial Primary Key,
Student_ID Int NOT NULL,
Book_ID Int NOT NULL,
Librarian_ID Int NOT NULL,
DateBorrowed Date NOT NULL,
DueDate Date NOT NULL,
Constraint fk_loans_student
	Foreign Key (Student_ID)
	References Students (Student_ID),

Constraint fk_loans_book
	Foreign Key (Book_ID)
	References Books (Book_ID),

Constraint fk_loans_librarian
	Foreign Key (Librarian_ID)
	References Librarians (Librarian_ID)
);
--------------------------------------------------------------
CREATE TABLE Fines(
Fine_ID Serial Primary Key,
Loan_ID Int NOT NULL,
Amount DECIMAL(6,2) NOT NULL,  --A decimal number with up to 6 total digits, where 2 digits are after the decimal point.
DateIssued Date NOT NULL,

Constraint fk_fine_loan
	Foreign Key (Loan_ID)
	References Loans (Loan_ID)
);

--2. Insert values
--2.1 Insert students
CREATE OR REPLACE PROCEDURE insert_students(num_records INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
  majors TEXT[] := ARRAY[
    'Computer Science',
    'Mathematics',
    'Biology',
    'Physics',
    'Chemistry',
    'Business',
    'Economics',
    'Engineering',
    'Psychology',
    'Art'
  ];
BEGIN
	FOR i IN 1..num_records LOOP
		INSERT INTO Students (Name, Major, Email, YearOfStudy)
		VALUES (
			'student' || i,
			majors[ floor(random() * array_length(majors, 1)) + 1 ],
			'student' || i || '@go.stcloudstate.edu',
			i % 4 + 1
		);
	END LOOP;
END $$;

CALL insert_students(25);

SELECT * FROM Students;
--2.1 Insert books
CREATE OR REPLACE PROCEDURE insert_books(num_records INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	FOR i IN 1..num_records LOOP
		INSERT INTO Books (Title, Author, Category, YearOfPublication)
		VALUES (
			'title' || i,
			'author' || i,
			'category' || i,
			2000 + (i % 25)
		);
	END LOOP;
END $$;

CALL insert_books(60);

SELECT * FROM Books;
--2.3 Insert librarians
CREATE OR REPLACE PROCEDURE insert_librarians(num_records INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE 
shifts TEXT[] := ARRAY['morning', 'evening'];
BEGIN
	FOR i IN 1..num_records LOOP
		INSERT INTO Librarians (Name, Email, Shift)
		VALUES (
			'librarian' || i,
			'librarian' || i || '@stcloudstate.edu',
			shifts[i % 2 + 1]
		);
	END LOOP;
END $$;

CALL insert_librarians(12);

SELECT * FROM Librarians;
--------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_loans(num_records INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
  borrowed_date TIMESTAMP;
BEGIN
	FOR i IN 1..num_records LOOP
		borrowed_date := NOW() - (random() * INTERVAL '7 days');
		INSERT INTO Loans (Student_ID, Book_ID, Librarian_ID, DateBorrowed, DueDate)
		VALUES (
			(SELECT Student_ID FROM Students ORDER BY random() LIMIT 1),
  			(SELECT Book_ID FROM Books ORDER BY random() LIMIT 1),
  			(SELECT Librarian_ID FROM Librarians ORDER BY random() LIMIT 1),
			borrowed_date,
			borrowed_date+(random() * INTERVAL '7 days')
		);
	END LOOP;
END $$;

CALL insert_loans(40);

--DELETE FROM Loans;

SELECT * FROM Loans;
--------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_fines()
LANGUAGE plpgsql
AS $$
DECLARE
  l RECORD;
  days_overdue INTEGER;
BEGIN
  FOR l IN
    SELECT loan_id, duedate
    FROM Loans
    WHERE duedate < NOW()
  LOOP
    days_overdue := FLOOR(EXTRACT(DAY FROM (NOW() - l.duedate)));

    INSERT INTO Fines (Loan_ID, Amount, DateIssued)
    VALUES (
      l.loan_id,
      days_overdue * 0.50,
      NOW()
    );
  END LOOP;
END $$;

CALL insert_fines();

SELECT * FROM Fines;

--4. SQL Queries
--4.1 JOIN + SELECT
SELECT 
  s.name AS student_name,
  b.title AS book_title,
  l.dateborrowed,
  l.duedate
FROM Loans l
JOIN Students s ON l.student_id = s.student_id
JOIN Books b ON l.book_id = b.book_id;

--4.2 Aggregation(COUNT) + GROUP BY + ORDER BY
SELECT 
  s.name,
  COUNT(l.loan_id) AS total_loans
FROM Students s
LEFT JOIN Loans l ON s.student_id = l.student_id
GROUP BY s.name
ORDER BY total_loans DESC;

--4.3 WHERE + JOIN
SELECT
  s.name AS student_name,
  b.title AS book_title,
  l.duedate
FROM Loans l
JOIN Students s ON l.student_id = s.student_id
JOIN Books b ON l.book_id = b.book_id
WHERE l.duedate < NOW();

--4.4 Aggregation（SUM）+ JOIN + GROUP BY + ORDER BY
SELECT
  s.name AS student_name,
  SUM(f.amount) AS total_fine
FROM Students s
JOIN Loans l ON s.student_id = l.student_id
JOIN Fines f ON l.loan_id = f.loan_id
GROUP BY s.name
ORDER BY total_fine DESC;

--4.5 AVG
SELECT
  s.name AS student_name,
  AVG(f.amount) AS average_fine
FROM Students s
JOIN Loans l ON s.student_id = l.student_id
JOIN Fines f ON l.loan_id = f.loan_id
GROUP BY s.name
ORDER BY average_fine DESC;

--4.6 INSERT
SELECT * FROM Loans;

INSERT INTO Loans (Student_ID, Book_ID, Librarian_ID, DateBorrowed, DueDate)
VALUES (
  (SELECT Student_ID FROM Students ORDER BY random() LIMIT 1),
  (SELECT Book_ID FROM Books ORDER BY random() LIMIT 1),
  (SELECT Librarian_ID FROM Librarians ORDER BY random() LIMIT 1),
  NOW(),
  NOW() + INTERVAL '14 days'
);

SELECT * FROM Loans;

--4.7 UPDATE + DELETE

SELECT * FROM Fines;

UPDATE Fines 
SET amount = amount * 1.10
WHERE amount > 5.00;

SELECT * FROM Fines;
DELETE FROM Fines;







