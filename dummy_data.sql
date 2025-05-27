-- Create the tables in accordance to the relevant Data Refiner schema
CREATE TABLE users (
	"UserID" VARCHAR NOT NULL, 
	"Source" VARCHAR NOT NULL, 
	"SourceUserId" VARCHAR NOT NULL, 
	"Status" VARCHAR NOT NULL, 
	"DateTimeCreated" DATETIME NOT NULL, 
	PRIMARY KEY ("UserID")
);

CREATE TABLE submissions (
	"SubmissionID" VARCHAR NOT NULL, 
	"UserID" VARCHAR NOT NULL, 
	"SubmissionDate" DATETIME NOT NULL, 
	"SubmissionReference" VARCHAR NOT NULL, 
	PRIMARY KEY ("SubmissionID"), 
	FOREIGN KEY("UserID") REFERENCES users ("UserID")
);

CREATE TABLE submission_chats (
	"SubmissionChatID" VARCHAR NOT NULL, 
	"SubmissionID" VARCHAR NOT NULL, 
	"SourceChatID" VARCHAR NOT NULL, 
	"FirstMessageDate" DATETIME NOT NULL, 
	"LastMessageDate" DATETIME NOT NULL, 
	"ParticipantCount" INTEGER, 
	"MessageCount" INTEGER NOT NULL, 
	PRIMARY KEY ("SubmissionChatID"), 
	FOREIGN KEY("SubmissionID") REFERENCES submissions ("SubmissionID")
);

CREATE TABLE chat_messages (
	"MessageID" VARCHAR NOT NULL, 
	"SubmissionChatID" VARCHAR NOT NULL, 
	"SourceMessageID" VARCHAR NOT NULL, 
	"SenderID" VARCHAR NOT NULL, 
	"MessageDate" DATETIME NOT NULL, 
	"ContentType" VARCHAR NOT NULL, 
	"Content" TEXT, 
	"ContentData" BLOB, 
	PRIMARY KEY ("MessageID"), 
	FOREIGN KEY("SubmissionChatID") REFERENCES submission_chats ("SubmissionChatID")
);

-- Seed dummy data representing ingested, refined Query Engine data points
INSERT INTO users ("UserID", "Source", "SourceUserId", "Status", "DateTimeCreated") VALUES
('u001', 'email', 'alice@example.com', 'active', '2024-04-01 09:00:00'),
('u002', 'email', 'bob@example.com', 'active', '2024-04-01 10:15:00'),
('u003', 'email', 'carol@example.com', 'active', '2024-04-01 11:30:00'),
('u004', 'email', 'dave@example.com', 'active', '2024-04-01 12:45:00'),
('u005', 'email', 'eve@example.com', 'active', '2024-04-01 13:00:00');

-- Create submissions for users
INSERT INTO submissions ("SubmissionID", "UserID", "SubmissionDate", "SubmissionReference") VALUES
('s001', 'u001', '2024-04-02 10:00:00', 'REF001'),
('s002', 'u002', '2024-04-02 11:30:00', 'REF002'),
('s003', 'u003', '2024-04-02 14:15:00', 'REF003');

-- Create chats for submissions
INSERT INTO submission_chats ("SubmissionChatID", "SubmissionID", "SourceChatID", "FirstMessageDate", "LastMessageDate", "ParticipantCount", "MessageCount") VALUES
('c001', 's001', 'src001', '2024-04-02 10:05:00', '2024-04-02 10:30:00', 2, 5),
('c002', 's002', 'src002', '2024-04-02 11:35:00', '2024-04-02 12:00:00', 3, 8),
('c003', 's003', 'src003', '2024-04-02 14:20:00', '2024-04-02 15:00:00', 2, 6);

-- Create messages for chats
INSERT INTO chat_messages ("MessageID", "SubmissionChatID", "SourceMessageID", "SenderID", "MessageDate", "ContentType", "Content") VALUES
('m001', 'c001', 'srcm001', 'u001', '2024-04-02 10:05:00', 'text', 'Hello! This is my first message.'),
('m002', 'c001', 'srcm002', 'u002', '2024-04-02 10:10:00', 'text', 'Hi there! Nice to meet you.');

-- Create the `results` table to simulate Query Engine query processing results.
CREATE TABLE results AS
SELECT
    "UserID",
    "Source",
    "Status"
FROM users; 