--BUSINESS GOAL 1: Tracking 'Most Liked Books' in a specific region. Here most liked books are determined by customer rating, higher the rating higher the book is on the most liked books list. We can use this information to understand the user demographics of every region.


SET PAGESIZE 250
SET LINESIZE 250


COL GENRE FORMAT A15
COL TITLE FORMAT A80
COL COUNTRY FORMAT A15
COL AVG_RATING FORMAT 999.99

WITH RankedBooks AS (
    SELECT
        B.GENRE,
        B.BOOK_NAME AS TITLE,
        C.COUNTRY,
        AVG(CAST(B.CUSTOMER_RATING AS DECIMAL(5, 2))) AS AVG_RATING,
        ROW_NUMBER() OVER (PARTITION BY B.GENRE, C.COUNTRY ORDER BY AVG(CAST(B.CUSTOMER_RATING AS DECIMAL(5, 2))) DESC) AS Ranking
    FROM
        F23_S003_T5_BOOKS B
        JOIN F23_S003_T5_READS R ON B.BOOKID = R.BOOKID
        JOIN F23_S003_T5_CUSTOMER_ADDRESS C ON R.CUSTOMERID = C.CustomerID
    GROUP BY
        B.GENRE,
        B.BOOK_NAME,
        C.COUNTRY
)
SELECT
    GENRE,
    TITLE,
    COUNTRY,
    AVG_RATING
FROM
    RankedBooks
WHERE
    Ranking = 1
ORDER BY
    GENRE, COUNTRY, AVG_RATING DESC;

--BUSINESS GOAL 2:This generates a report on readers, their locations, the genres of books they have read, and the count of books for each combination of these factors.The rollup gives a sum total as well that can be used for our analysis.

SET LINESIZE 250
SET PAGESIZE 700

COL CA.Country FORMAT A15
COL CA.City FORMAT A15
COL CA.ZIPCode FORMAT A10
COL A.AUTHOR_NAME FORMAT A30
COL B.GENRE FORMAT A10
COLUMN BookCount FORMAT 99999

SELECT
    CA.Country,
    CA.City,
    CA.ZIPCode,
    FLOOR((SYSDATE - C.DOB) / 365.25) AS Age,
    A.AUTHOR_NAME,
    B.GENRE,
    COUNT(*) AS BookCount
FROM
    F23_S003_T5_CUSTOMER C
JOIN
    F23_S003_T5_CUSTOMER_ADDRESS CA ON C.CUSTOMERID = CA.CUSTOMERID
JOIN
    F23_S003_T5_READS R ON C.CUSTOMERID = R.CUSTOMERID
JOIN
    F23_S003_T5_BOOKS B ON R.BOOKID = B.BOOKID
JOIN
    F23_S003_T5_WRITES W ON B.BOOKID = W.BOOKID
JOIN
    F23_S003_T5_AUTHORS A ON W.AUTHORID = A.AUTHORID
GROUP BY
    ROLLUP(CA.Country, CA.City, CA.ZIPCode, FLOOR((SYSDATE - C.DOB) / 365.25), A.AUTHOR_NAME, B.GENRE)
ORDER BY
    CA.Country, CA.City, CA.ZIPCode, Age, A.AUTHOR_NAME, B.GENRE;


--BUSINESS GOAL 3: Increasing readership base by attracting more diverse readers. For example,February is Black History Month, so we feature authors and works focusing on that theme. This is why we have captured ethnicity and location for our author database.This query gives a list of authors who are people of color,and are born outside of the USA. This showcases the diversity we have and can be used for marketing.

SET LINESIZE 120
SET PAGESIZE 500

COL AUTHOR_NAME FORMAT A30
COL BIRTH_COUNTRY FORMAT A20
COL BOOK_NAME FORMAT A50

SELECT
    A.AUTHOR_NAME,
    A.COUNTRY AS BIRTH_COUNTRY,
    B.BOOK_NAME,
    B.CUSTOMER_RATING
FROM
    F23_S003_T5_AUTHORS A
JOIN
    F23_S003_T5_WRITES W ON A.AUTHORID = W.AUTHORID
JOIN
    F23_S003_T5_BOOKS B ON W.BOOKID = B.BOOKID
WHERE
    (A.ETHNICITY <> 'White' AND A.COUNTRY <> 'USA')
    AND B.CUSTOMER_RATING BETWEEN 4.0 AND 5.0
GROUP BY
    A.AUTHORID, A.AUTHOR_NAME, A.COUNTRY, B.BOOKID, B.BOOK_NAME, B.CUSTOMER_RATING
HAVING
    COUNT(*) >= 1
ORDER BY
    A.AUTHOR_NAME, B.CUSTOMER_RATING DESC;

--BUSINESS GOAL 4: This query retrieves the customer details (ID, first name, last name, date of birth, occupation) and the books they have read (book ID, book name, genre, price) for customers with the occupation ‘Doctor’. We can also use the same query for other professions too. This information can be used to offer targeted ads and discounts on books.

SET LINESIZE 120
SET PAGESIZE 500

COL CUSTOMERID FORMAT A10
COL B.BOOK_NAME FORMAT A20
COL C.Occupation FORMAT A10
COL B.BOOKID FORMAT A10
COL B.GENRE FORMAT A10

SELECT C.CUSTOMERID, C.Fname, C.Lname, C.DOB, C.Occupation, B.BOOKID, B.BOOK_NAME, B.GENRE, B.PRICE
FROM F23_S003_T5_CUSTOMER C
JOIN F23_S003_T5_READS R ON C.CUSTOMERID = R.CUSTOMERID
JOIN F23_S003_T5_BOOKS B ON R.BOOKID = B.BOOKID
WHERE C.Occupation IN ('Doctor',  'Doctor ')
ORDER BY C.DOB;

--BUSINESS GOAL 5:Finding the total number of readers for each genre in each country using Rollup. When we get the total number of readers based on countries and genres, we can use that information to determine our marketing strategy. The genres with more readers can be marketed more extensively to drive higher sales.

SET LINESIZE 200
SET PAGESIZE 200
COL COUNTRY FORMAT A10 
COL GENRE FORMAT A20 
COL TOTALREADERS FORMAT 999 
SELECT 
    C.Country,
    B.GENRE,
    COUNT(*) AS TotalReaders
FROM 
    F23_S003_T5_CUSTOMER_ADDRESS C
JOIN 
    F23_S003_T5_READS R ON C.CUSTOMERID = R.CUSTOMERID
JOIN 
    F23_S003_T5_BOOKS B ON R.BOOKID = B.BOOKID
WHERE 
    C.Country IN ('USA', 'Canada', 'Mexico')
GROUP BY 
    ROLLUP(C.Country, B.GENRE)
ORDER BY 
    Country, GENRE, TotalReaders DESC;


--BUSINESS GOAL 6: Tracking book sales of each publishing house. This query gives a list of the top 20 publishers who have the highest sales.This will help make decisions of the number of books the publishers have to sell. For example, Anyone with sales less than 50$, can consider publishing more books and increase their sales output.

SET LINESIZE 250
SET PAGESIZE 500

SELECT
    P.PUBLISHERID,
    P.PUBLISHER_NAME,
    COUNT(B.BOOKID) AS NumberOfBooks,
    SUM(B.PRICE) AS TotalSales
FROM
    F23_S003_T5_PUBLISHER P
JOIN
    F23_S003_T5_BOOKS_PUBLISHED_BY BP ON P.PUBLISHERID = BP.PUBLISHERID
JOIN
    F23_S003_T5_BOOKS B ON BP.BOOKID = B.BOOKID
GROUP BY
    P.PUBLISHERID, P.PUBLISHER_NAME
ORDER BY
 TotalSales DESC
FETCH FIRST 20 ROWS ONLY;

--BUSINESS GOAL 7: We can understand the reader demographics using this. We will know which genre has the highest rated books.Publishers can use this info to decide which genres they want to publish more or which books can be priced higher. 

SET LINESIZE 150
SET PAGESIZE 500

SELECT DISTINCT
    GENRE,
    AVG(CUSTOMER_RATING) OVER (PARTITION BY GENRE) AS AvgRatingByGenre
FROM
    F23_S003_T5_BOOKS
ORDER BY
    GENRE;

--BUSINESS GOAL 8: This gives a list of customers who have read all books. We can use this information to track customer preferences. 
SELECT B.BOOK_NAME
FROM F23_S003_T5_BOOKS B
WHERE NOT EXISTS (
    SELECT C.CUSTOMERID
    FROM F23_S003_T5_CUSTOMER C
    MINUS
    SELECT R.CUSTOMERID
    FROM F23_S003_T5_READS R
    WHERE R.BOOKID = B.BOOKID
);

--BUSINESS GOAL 9: This query gives a list of all books with a rating of more than 3.5 written by authors born before 1990: Publishers can use this information to bring in more authors of diverse age groups.

SET LINESIZE 200
SET PAGESIZE 500
COL B.CUSTOMER_RATING FORMAT A20
COL A.AUTHOR_NAME FORMAT A20
COL A.DOB FORMAT A10

SELECT
    B.BOOK_NAME,
    B.CUSTOMER_RATING,
    A.AUTHOR_NAME,
    A.DOB
FROM
    F23_S003_T5_BOOKS B
JOIN
    F23_S003_T5_WRITES W ON B.BOOKID = W.BOOKID
JOIN
    F23_S003_T5_AUTHORS A ON W.AUTHORID = A.AUTHORID
WHERE
    B.CUSTOMER_RATING > 3.5
    AND EXTRACT(YEAR FROM A.DOB) < 1990
GROUP BY
    B.BOOKID,
    B.BOOK_NAME,
    B.CUSTOMER_RATING,
    A.AUTHORID,
    A.AUTHOR_NAME,
    A.DOB
HAVING
    COUNT(DISTINCT B.BOOKID) = 1;

--BUSINESS GOAL 10:Expanding readership in other countries involves analyzing sales data, understanding genre preferences, and obtaining relevant information.The output for this query shows the reading habits vary across different age groups, genres, and countries, allowing us to analyze patterns and preferences in the data.

SET LINESIZE 150
SET PAGESIZE 500

SELECT
    CA.Country,
    FLOOR((SYSDATE - C.DOB) / 365.25) AS Age,
    B.GENRE,
    COUNT(*) AS BookCount
FROM
    F23_S003_T5_CUSTOMER C
JOIN
    F23_S003_T5_CUSTOMER_ADDRESS CA ON C.CUSTOMERID = CA.CUSTOMERID
JOIN
    F23_S003_T5_READS R ON C.CUSTOMERID = R.CUSTOMERID
JOIN
    F23_S003_T5_BOOKS B ON R.BOOKID = B.BOOKID
WHERE
    CA.Country IN ('Canada', 'USA', 'Mexico')
GROUP BY
    CA.Country, FLOOR((SYSDATE - C.DOB) / 365.25), B.GENRE
HAVING
    COUNT(*) > 1
ORDER BY
    CA.Country, Age, B.GENRE, BookCount DESC;

--BUSINESS GOAL 11:Expanding readership in other countries involves analyzing sales data, understanding genre preferences, and obtaining relevant information. The output for this query provides insights into books that are published in more than one language, which is useful for understanding the linguistic diversity of the books in the dataset and for catering to a multilingual audience.

SET LINESIZE 120
SET PAGESIZE 200

COL B.BOOK_NAME FORMAT A50
COL BL.LANGUAGE FORMAT A50

SELECT
    B.BOOK_NAME,
    B.GENRE,
    BL.LANGUAGE
FROM
    F23_S003_T5_BOOKS B
JOIN
    F23_S003_T5_BOOK_LANGUAGE BL ON B.BOOKID = BL.BOOKID
WHERE
    BL.LANGUAGE LIKE '%,%';



 






