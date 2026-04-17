-- test_data.sql
-- Seed data for trojanmarket schema (MySQL 8.0+)
-- Usage: mysql -u <user> -p < c:/Users/matthewd/Downloads/test_data.sql

USE trojanmarket;

START TRANSACTION;

-- Remove previously seeded data (idempotent reruns).
DROP TEMPORARY TABLE IF EXISTS tmp_seed_users;
CREATE TEMPORARY TABLE tmp_seed_users AS
SELECT userID
FROM Users
WHERE username LIKE 'seed_%';

DELETE FROM Transactions
WHERE buyerID IN (SELECT userID FROM tmp_seed_users)
   OR sellerID IN (SELECT userID FROM tmp_seed_users);

DELETE FROM Messages
WHERE senderID IN (SELECT userID FROM tmp_seed_users)
   OR sessionID IN (
       SELECT sessionID
       FROM ChatSessions
       WHERE buyerID IN (SELECT userID FROM tmp_seed_users)
          OR sellerID IN (SELECT userID FROM tmp_seed_users)
   );

DELETE FROM ChatSessions
WHERE buyerID IN (SELECT userID FROM tmp_seed_users)
   OR sellerID IN (SELECT userID FROM tmp_seed_users);

DELETE FROM Postings
WHERE sellerID IN (SELECT userID FROM tmp_seed_users);

DELETE FROM Users
WHERE userID IN (SELECT userID FROM tmp_seed_users);

DROP TEMPORARY TABLE tmp_seed_users;

-- Seed users.
INSERT INTO Users (username, password, email, isVerified, review, is_active)
VALUES
    ('seed_alice', 'hash_seed_alice', 'seed_alice@example.com', TRUE, 14, TRUE),
    ('seed_bob', 'hash_seed_bob', 'seed_bob@example.com', TRUE, 9, TRUE),
    ('seed_carla', 'hash_seed_carla', 'seed_carla@example.com', FALSE, 2, TRUE),
    ('seed_diego', 'hash_seed_diego', 'seed_diego@example.com', TRUE, 7, TRUE),
    ('seed_erika', 'hash_seed_erika', 'seed_erika@example.com', TRUE, 20, TRUE),
    ('seed_frank', 'hash_seed_frank', 'seed_frank@example.com', FALSE, 0, TRUE);

SELECT userID INTO @alice_id FROM Users WHERE username = 'seed_alice';
SELECT userID INTO @bob_id FROM Users WHERE username = 'seed_bob';
SELECT userID INTO @carla_id FROM Users WHERE username = 'seed_carla';
SELECT userID INTO @diego_id FROM Users WHERE username = 'seed_diego';
SELECT userID INTO @erika_id FROM Users WHERE username = 'seed_erika';
SELECT userID INTO @frank_id FROM Users WHERE username = 'seed_frank';

-- Seed postings.
INSERT INTO Postings (sellerID, title, description, category, status, price, is_active)
VALUES
    (@alice_id, 'SEED: Calculus Textbook', 'Stewart Calculus 8th edition, light notes.', 'TEXTBOOKS', 'AVAILABLE', 45.00, TRUE),
    (@bob_id, 'SEED: Dorm Mini Fridge', '3.2 cu ft mini fridge, works great.', 'ELECTRONICS', 'AVAILABLE', 80.00, TRUE),
    (@carla_id, 'SEED: Desk Lamp', 'LED lamp with adjustable brightness.', 'FURNITURE', 'PENDING', 18.50, TRUE),
    (@diego_id, 'SEED: Winter Jacket', 'Men\'s medium, gently used.', 'CLOTHING', 'AVAILABLE', 30.00, TRUE),
    (@erika_id, 'SEED: iClicker Remote', 'Used for lecture attendance.', 'ELECTRONICS', 'SOLD', 20.00, TRUE),
    (@alice_id, 'SEED: Storage Bin Set', 'Set of 3 stackable bins.', 'OTHER', 'SOLD', 25.00, TRUE);

SELECT postID INTO @calc_post_id
FROM Postings
WHERE title = 'SEED: Calculus Textbook' AND sellerID = @alice_id
ORDER BY postID DESC
LIMIT 1;

SELECT postID INTO @fridge_post_id
FROM Postings
WHERE title = 'SEED: Dorm Mini Fridge' AND sellerID = @bob_id
ORDER BY postID DESC
LIMIT 1;

SELECT postID INTO @lamp_post_id
FROM Postings
WHERE title = 'SEED: Desk Lamp' AND sellerID = @carla_id
ORDER BY postID DESC
LIMIT 1;

SELECT postID INTO @iclicker_post_id
FROM Postings
WHERE title = 'SEED: iClicker Remote' AND sellerID = @erika_id
ORDER BY postID DESC
LIMIT 1;

SELECT postID INTO @bin_post_id
FROM Postings
WHERE title = 'SEED: Storage Bin Set' AND sellerID = @alice_id
ORDER BY postID DESC
LIMIT 1;

-- Seed chat sessions.
INSERT INTO ChatSessions (postID, buyerID, sellerID)
VALUES
    (@calc_post_id, @frank_id, @alice_id),
    (@fridge_post_id, @carla_id, @bob_id),
    (@lamp_post_id, @diego_id, @carla_id),
    (@iclicker_post_id, @bob_id, @erika_id),
    (@bin_post_id, @diego_id, @alice_id);

SELECT sessionID INTO @chat_calc_id
FROM ChatSessions
WHERE postID = @calc_post_id AND buyerID = @frank_id AND sellerID = @alice_id
ORDER BY sessionID DESC
LIMIT 1;

SELECT sessionID INTO @chat_fridge_id
FROM ChatSessions
WHERE postID = @fridge_post_id AND buyerID = @carla_id AND sellerID = @bob_id
ORDER BY sessionID DESC
LIMIT 1;

SELECT sessionID INTO @chat_lamp_id
FROM ChatSessions
WHERE postID = @lamp_post_id AND buyerID = @diego_id AND sellerID = @carla_id
ORDER BY sessionID DESC
LIMIT 1;

SELECT sessionID INTO @chat_iclicker_id
FROM ChatSessions
WHERE postID = @iclicker_post_id AND buyerID = @bob_id AND sellerID = @erika_id
ORDER BY sessionID DESC
LIMIT 1;

SELECT sessionID INTO @chat_bins_id
FROM ChatSessions
WHERE postID = @bin_post_id AND buyerID = @diego_id AND sellerID = @alice_id
ORDER BY sessionID DESC
LIMIT 1;

-- Seed messages.
INSERT INTO Messages (sessionID, senderID, messageText, is_read)
VALUES
    (@chat_calc_id, @frank_id, 'Hi, is this textbook still available?', TRUE),
    (@chat_calc_id, @alice_id, 'Yes, still available. Pickup on campus works.', TRUE),
    (@chat_fridge_id, @carla_id, 'Can you do 70 if I pick up tonight?', FALSE),
    (@chat_fridge_id, @bob_id, 'Could do 75, includes power cable.', FALSE),
    (@chat_lamp_id, @diego_id, 'Interested. Any scratches?', TRUE),
    (@chat_lamp_id, @carla_id, 'Very minor wear, fully functional.', TRUE),
    (@chat_iclicker_id, @bob_id, 'Will this pair with BIO lecture?', TRUE),
    (@chat_iclicker_id, @erika_id, 'Yes, used it last semester for BIO.', TRUE),
    (@chat_bins_id, @diego_id, 'Can pick up tomorrow afternoon.', FALSE),
    (@chat_bins_id, @alice_id, 'Sounds good, see you at 3 PM.', FALSE);

-- Seed transactions for sold items.
INSERT INTO Transactions (postID, buyerID, sellerID, sale_price)
VALUES
    (@iclicker_post_id, @bob_id, @erika_id, 20.00),
    (@bin_post_id, @diego_id, @alice_id, 25.00);

COMMIT;

-- Quick summary output.
SELECT 'USERS_SEEDED' AS metric, COUNT(*) AS value
FROM Users
WHERE username LIKE 'seed_%'
UNION ALL
SELECT 'POSTINGS_SEEDED', COUNT(*)
FROM Postings
WHERE title LIKE 'SEED:%'
UNION ALL
SELECT 'CHATSESSIONS_SEEDED', COUNT(*)
FROM ChatSessions
WHERE buyerID IN (SELECT userID FROM Users WHERE username LIKE 'seed_%')
   OR sellerID IN (SELECT userID FROM Users WHERE username LIKE 'seed_%')
UNION ALL
SELECT 'MESSAGES_SEEDED', COUNT(*)
FROM Messages
WHERE senderID IN (SELECT userID FROM Users WHERE username LIKE 'seed_%')
UNION ALL
SELECT 'TRANSACTIONS_SEEDED', COUNT(*)
FROM Transactions
WHERE buyerID IN (SELECT userID FROM Users WHERE username LIKE 'seed_%')
   OR sellerID IN (SELECT userID FROM Users WHERE username LIKE 'seed_%');
