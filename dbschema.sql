-- doing this just in case so that we don't run into issues with DB being weird when running script multiple times
-- DROP DATABASE trojanmarket;

CREATE DATABASE trojanmarket CHARACTER SET uft8mb4 COLLATE utf8mb4_unicode_ci;
USE trojanmarket;

-- user table setup
CREATE TABLE Users (
    userID INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(25) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- maybe want hashed pw? leaving it long if so
    email VARCHAR(50) NOT NULL UNIQUE,
    isVerified BOOLEAN DEFAULT FALSE,
    review INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE -- for soft-deletion/archive, will flip to FALSE when user acc is "deleted" by user
);

-- posting table setup
-- TODO: test how fkeys work when posting is archived
CREATE TABLE Postings (
    postID INT AUTO_INCREMENT PRIMARY KEY,
    sellerID INT NOT NULL,
    title VARCHAR(50) NOT NULL,
    description VARCHAR(250),
    category ENUM('TEXTBOOKS', 'ELECTRONICS', 'FURNITURE', 'CLOTHING', 'OTHER') NOT NULL,
    status ENUM('SOLD', 'PENDING', 'AVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
    price DECIMAL(10,2) NOT NULL,
    postTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE, -- for soft-deletion/archive, will flip to FALSE when posting is archived/deleted by seller
    FOREIGN KEY (sellerID) REFERENCES Users(userID) ON DELETE RESTRICT
);

-- chat sessions table setup
-- TODO: test how the fkeys work when posting is archived
CREATE TABLE ChatSessions (
    sessionID INT AUTO_INCREMENT PRIMARY KEY,
    postID INT NOT NULL,
    buyerID INT NOT NULL,
    sellerID INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (postID) REFERENCES Postings(postID) ON DELETE CASCADE, -- cascade since we don't rly care about the chat if the post got nuked
    FOREIGN KEY (buyerID) REFERENCES Users(userID) ON DELETE RESTRICT,
    FOREIGN KEY (sellerID) REFERENCES Users(userID) ON DELETE RESTRICT
);

-- messages table
-- TODO: test how fkeys work when chat session/message is deleted/archived
CREATE TABLE Messages (
    messageID INT AUTO_INCREMENT PRIMARY KEY,
    sessionID INT NOT NULL,
    senderID INT NOT NULL,
    messageText TEXT NOT NULL,
    messageTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (sessionID) REFERENCES ChatSessions(sessionID) ON DELETE CASCADE,
    FOREIGN KEY (senderID) REFERENCES Users(userID) ON DELETE RESTRICT
);

-- transactions table
-- current logic when a posting is deleted makes it so that nothing is removed from transactions even if the posting is gone, just in case
-- TODO: should be no issue when postings or wtv is archived, brief tests for this
CREATE TABLE Transactions (
    transactionID INT AUTO_INCREMENT PRIMARY KEY,
    postID INT NOT NULL,
    buyerID INT NOT NULL,
    sellerID INT NOT NULL,
    sale_price DECIMAL(10,2) NOT NULL,
    transactionTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (postID) REFERENCES Postings(postID) ON DELETE RESTRICT,
    FOREIGN KEY (buyerID) REFERENCES Users(userID) ON DELETE RESTRICT,
    FOREIGN KEY (sellerID) REFERENCES Users(userID) ON DELETE RESTRICT
);
