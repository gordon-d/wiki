DROP DATABASE IF EXISTS wiki_db;
CREATE DATABASE wiki_db;
\c wiki_db;

CREATE TABLE users(
	id SERIAL PRIMARY KEY,
	name VARCHAR,
	email VARCHAR,
	password VARCHAR
);

CREATE TABLE articles(
	id SERIAL PRIMARY KEY,
	title VARCHAR,
	content TEXT,
	last_edited TIMESTAMP,
	edited_by INTEGER REFERENCES users(id)
);