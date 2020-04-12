DROP DATABASE IF EXISTS test;
CREATE DATABASE test;

\c test;

CREATE TABLE book(
   id INT NOT NULL,
   title VARCHAR(100) NOT NULL,
   author VARCHAR(40) NOT NULL,
   publication_date DATE,
   PRIMARY KEY ( id )
);

\copy book FROM '/data/books.csv' DELIMITER ',' CSV HEADER;
