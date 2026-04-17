-- verify.sql
-- Post-deployment verification for dbschema.sql
-- Usage: mysql -u <user> -p < PATH-TO-FILE/verify.sql

SET @db_name := 'trojanmarket';

SELECT 'DATABASE_EXISTS' AS check_name,
       CASE
           WHEN EXISTS (
               SELECT 1
               FROM information_schema.schemata
               WHERE schema_name = @db_name
           ) THEN 'PASS'
           ELSE 'FAIL'
       END AS result,
       CONCAT('Schema ', @db_name, ' exists') AS details;

SELECT 'DATABASE_CHARSET_COLLATION' AS check_name,
       CASE
           WHEN EXISTS (
               SELECT 1
               FROM information_schema.schemata
               WHERE schema_name = @db_name
                 AND default_character_set_name = 'utf8mb4'
                 AND default_collation_name = 'utf8mb4_unicode_ci'
           ) THEN 'PASS'
           ELSE 'FAIL'
       END AS result,
       'Expected utf8mb4 / utf8mb4_unicode_ci' AS details;

SELECT 'TABLES_PRESENT' AS check_name,
       CASE
           WHEN (
               SELECT COUNT(*)
               FROM information_schema.tables
               WHERE table_schema = @db_name
                 AND table_name IN ('Users', 'Postings', 'ChatSessions', 'Messages', 'Transactions')
           ) = 5 THEN 'PASS'
           ELSE 'FAIL'
       END AS result,
       'Expected tables: Users, Postings, ChatSessions, Messages, Transactions' AS details;

SELECT 'COLUMN_COUNT_USERS' AS check_name,
       CASE WHEN (
           SELECT COUNT(*)
           FROM information_schema.columns
           WHERE table_schema = @db_name
             AND table_name = 'Users'
       ) = 7 THEN 'PASS' ELSE 'FAIL' END AS result,
       'Expected 7 columns' AS details;

SELECT 'COLUMN_COUNT_POSTINGS' AS check_name,
       CASE WHEN (
           SELECT COUNT(*)
           FROM information_schema.columns
           WHERE table_schema = @db_name
             AND table_name = 'Postings'
       ) = 9 THEN 'PASS' ELSE 'FAIL' END AS result,
       'Expected 9 columns' AS details;

SELECT 'COLUMN_COUNT_CHATSESSIONS' AS check_name,
       CASE WHEN (
           SELECT COUNT(*)
           FROM information_schema.columns
           WHERE table_schema = @db_name
             AND table_name = 'ChatSessions'
       ) = 5 THEN 'PASS' ELSE 'FAIL' END AS result,
       'Expected 5 columns' AS details;

SELECT 'COLUMN_COUNT_MESSAGES' AS check_name,
       CASE WHEN (
           SELECT COUNT(*)
           FROM information_schema.columns
           WHERE table_schema = @db_name
             AND table_name = 'Messages'
       ) = 6 THEN 'PASS' ELSE 'FAIL' END AS result,
       'Expected 6 columns' AS details;

SELECT 'COLUMN_COUNT_TRANSACTIONS' AS check_name,
       CASE WHEN (
           SELECT COUNT(*)
           FROM information_schema.columns
           WHERE table_schema = @db_name
             AND table_name = 'Transactions'
       ) = 6 THEN 'PASS' ELSE 'FAIL' END AS result,
       'Expected 6 columns' AS details;

SELECT 'FOREIGN_KEY_COUNT' AS check_name,
       CASE
           WHEN (
               SELECT COUNT(*)
               FROM information_schema.table_constraints
               WHERE table_schema = @db_name
                 AND table_name IN ('Postings', 'ChatSessions', 'Messages', 'Transactions')
                 AND constraint_type = 'FOREIGN KEY'
           ) = 9 THEN 'PASS'
           ELSE 'FAIL'
       END AS result,
       'Expected 9 foreign keys total' AS details;

SET @can_smoke_test := (
    SELECT CASE WHEN (
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = @db_name
          AND table_name IN ('Users', 'Postings', 'ChatSessions', 'Messages', 'Transactions')
    ) = 5 THEN 1 ELSE 0 END
);

DELIMITER //

DROP PROCEDURE IF EXISTS verify_smoke_test //
CREATE PROCEDURE verify_smoke_test()
BEGIN
    DECLARE v_suffix VARCHAR(6);
    DECLARE v_seller_username VARCHAR(25);
    DECLARE v_buyer_username VARCHAR(25);
    DECLARE v_seller_email VARCHAR(50);
    DECLARE v_buyer_email VARCHAR(50);

    IF @can_smoke_test = 0 THEN
        SELECT 'SMOKE_TEST_READY' AS check_name,
               'SKIP' AS result,
               'Missing required tables; smoke test not run' AS details;
    ELSE
        SET v_suffix = LPAD(FLOOR(RAND() * 1000000), 6, '0');
        SET v_seller_username = CONCAT('vs_', v_suffix);
        SET v_buyer_username = CONCAT('vb_', v_suffix);
        SET v_seller_email = CONCAT('vs_', v_suffix, '@ex.com');
        SET v_buyer_email = CONCAT('vb_', v_suffix, '@ex.com');

        START TRANSACTION;

        INSERT INTO trojanmarket.Users (username, password, email, isVerified, review, is_active)
        VALUES (v_seller_username, 'verify_password_hash', v_seller_email, TRUE, 0, TRUE);
        SET @seller_id := LAST_INSERT_ID();

        INSERT INTO trojanmarket.Users (username, password, email, isVerified, review, is_active)
        VALUES (v_buyer_username, 'verify_password_hash', v_buyer_email, TRUE, 0, TRUE);
        SET @buyer_id := LAST_INSERT_ID();

        INSERT INTO trojanmarket.Postings (sellerID, title, description, category, status, price, is_active)
        VALUES (@seller_id, 'Verify Listing', 'Smoke test listing', 'OTHER', 'AVAILABLE', 12.34, TRUE);
        SET @post_id := LAST_INSERT_ID();

        INSERT INTO trojanmarket.ChatSessions (postID, buyerID, sellerID)
        VALUES (@post_id, @buyer_id, @seller_id);
        SET @session_id := LAST_INSERT_ID();

        INSERT INTO trojanmarket.Messages (sessionID, senderID, messageText, is_read)
        VALUES (@session_id, @buyer_id, 'Smoke test message', FALSE);
        SET @message_id := LAST_INSERT_ID();

        INSERT INTO trojanmarket.Transactions (postID, buyerID, sellerID, sale_price)
        VALUES (@post_id, @buyer_id, @seller_id, 12.34);
        SET @transaction_id := LAST_INSERT_ID();

        SELECT 'SMOKE_TEST_INSERTS' AS check_name,
               CASE
                   WHEN EXISTS (SELECT 1 FROM trojanmarket.Users WHERE userID = @seller_id)
                    AND EXISTS (SELECT 1 FROM trojanmarket.Users WHERE userID = @buyer_id)
                    AND EXISTS (SELECT 1 FROM trojanmarket.Postings WHERE postID = @post_id)
                    AND EXISTS (SELECT 1 FROM trojanmarket.ChatSessions WHERE sessionID = @session_id)
                    AND EXISTS (SELECT 1 FROM trojanmarket.Messages WHERE messageID = @message_id)
                    AND EXISTS (SELECT 1 FROM trojanmarket.Transactions WHERE transactionID = @transaction_id)
                   THEN 'PASS'
                   ELSE 'FAIL'
               END AS result,
               'Inserted and linked sample rows successfully' AS details;

        ROLLBACK;

        SELECT 'SMOKE_TEST_ROLLBACK' AS check_name,
               CASE
                   WHEN NOT EXISTS (SELECT 1 FROM trojanmarket.Users WHERE userID IN (@seller_id, @buyer_id))
                    AND NOT EXISTS (SELECT 1 FROM trojanmarket.Postings WHERE postID = @post_id)
                    AND NOT EXISTS (SELECT 1 FROM trojanmarket.ChatSessions WHERE sessionID = @session_id)
                    AND NOT EXISTS (SELECT 1 FROM trojanmarket.Messages WHERE messageID = @message_id)
                    AND NOT EXISTS (SELECT 1 FROM trojanmarket.Transactions WHERE transactionID = @transaction_id)
                   THEN 'PASS'
                   ELSE 'FAIL'
               END AS result,
               'Transaction rolled back cleanly (no test rows left behind)' AS details;
    END IF;
END //

DELIMITER ;

CALL verify_smoke_test();
DROP PROCEDURE verify_smoke_test;
