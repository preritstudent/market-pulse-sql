USE StockMarket;

-- Table 1: Company info
CREATE TABLE companies (
    ticker      VARCHAR(10)  PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    sector      VARCHAR(50),
    country     VARCHAR(50)
);

-- Table 2: Daily stock prices
CREATE TABLE stock_prices (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    ticker      VARCHAR(10)  NOT NULL,
    price_date  DATE         NOT NULL,
    open_price  DECIMAL(10,2),
    close_price DECIMAL(10,2),
    high_price  DECIMAL(10,2),
    low_price   DECIMAL(10,2),
    volume      BIGINT
);

-- Add 5 well-known companies
INSERT INTO companies VALUES ('AAPL', 'Apple Inc.',        'Technology',   'USA');
INSERT INTO companies VALUES ('TSLA', 'Tesla Inc.',        'Automotive',   'USA');
INSERT INTO companies VALUES ('GOOGL','Alphabet Inc.',     'Technology',   'USA');
INSERT INTO companies VALUES ('MSFT', 'Microsoft Corp.',   'Technology',   'USA');
INSERT INTO companies VALUES ('AMZN', 'Amazon.com Inc.',   'E-Commerce',   'USA');

-- Add some price data
INSERT INTO stock_prices (ticker, price_date, open_price, close_price, high_price, low_price, volume) VALUES
('AAPL', '2024-01-02', 185.00, 187.15, 188.20, 184.50, 52000000),
('AAPL', '2024-01-03', 187.00, 184.40, 187.90, 183.80, 48000000),
('AAPL', '2024-01-04', 184.50, 182.30, 185.10, 181.90, 55000000),
('TSLA', '2024-01-02', 250.00, 248.50, 253.00, 247.00, 31000000),
('TSLA', '2024-01-03', 248.50, 255.00, 256.40, 247.80, 38000000),
('TSLA', '2024-01-04', 255.00, 251.30, 257.00, 250.00, 29000000),
('MSFT', '2024-01-02', 374.00, 376.40, 377.50, 373.00, 21000000),
('MSFT', '2024-01-03', 376.00, 373.90, 376.80, 372.50, 19000000),
('GOOGL','2024-01-02', 140.00, 141.80, 142.50, 139.50, 24000000),
('AMZN', '2024-01-02', 153.00, 155.20, 156.00, 152.50, 44000000);


-- See all companies
SELECT * FROM companies;

-- See all price data
SELECT * FROM stock_prices;

-- Only Apple prices
SELECT * FROM stock_prices
WHERE ticker = 'AAPL';

-- Only closing prices, cleanly
SELECT ticker, price_date, close_price
FROM stock_prices
WHERE ticker = 'TSLA';

SELECT company_name, country 
FROM companies
WHERE sector  = 'Automotive';



-- PHASE 2: Sorting & Aggregation

-- Which stock had the highest closing price ever?
SELECT ticker, price_date, close_price
FROM stock_prices
ORDER BY close_price DESC;

-- Which stock had the highest opening price ever?
SELECT ticker, price_date, open_price
FROM stock_prices
ORDER BY open_price DESC;


-- Average closing price per stock
SELECT ticker, AVG(close_price) AS avg_close
FROM stock_prices
GROUP BY ticker;

-- Best single-day closing price per stock
SELECT ticker, MAX(close_price) AS best_close
FROM stock_prices
GROUP BY ticker
ORDER BY best_close DESC;

-- Which day had the most trading volume? (most active market day)
SELECT price_date, SUM(volume) AS total_volume
FROM stock_prices
GROUP BY price_date
ORDER BY total_volume DESC;

-- How many days of data do we have per stock?
SELECT ticker, COUNT(*) AS trading_days
FROM stock_prices
GROUP BY ticker;

-- PHASE 3: JOINs

-- Basic JOIN: show company name alongside its prices
SELECT c.company_name, c.sector, sp.price_date, sp.close_price
FROM stock_prices AS sp
INNER JOIN companies AS c ON sp.ticker = c.ticker;

-- -try case 
SELECT c.country, sp.high_price
FROM stock_prices AS sp 
INNER JOIN companies AS c ON sp.ticker = c.ticker;

-- Which sector had the highest average closing price?
SELECT c.sector, AVG(sp.close_price) AS avg_close
FROM stock_prices AS sp
INNER JOIN companies AS c ON sp.ticker = c.ticker
GROUP BY c.sector
ORDER BY avg_close DESC;

-- Full company name with their best single day price
SELECT c.company_name, MAX(sp.close_price) AS best_price
FROM stock_prices AS sp
INNER JOIN companies AS c ON sp.ticker = c.ticker
GROUP BY c.company_name
ORDER BY best_price DESC;

-- Show all companies even if they have NO price data (LEFT JOIN)
SELECT c.company_name, c.sector, sp.close_price, sp.price_date
FROM companies AS c
LEFT JOIN stock_prices AS sp ON c.ticker = sp.ticker;


-- PHASE 4: Subqueries & CTEs

-- SUBQUERY: stocks with closing price above overall market average
SELECT ticker, price_date, close_price
FROM stock_prices
WHERE close_price > (SELECT AVG(close_price) FROM stock_prices);

-- SUBQUERY: companies that have more than 1 day of price data
SELECT company_name, sector
FROM companies
WHERE ticker IN (
    SELECT ticker
    FROM stock_prices
    GROUP BY ticker
    HAVING COUNT(*) > 1
);

-- CTE: calculate each stock's average, then rank them
WITH stock_avg AS (
    SELECT ticker, AVG(close_price) AS avg_close
    FROM stock_prices
    GROUP BY ticker
)
SELECT c.company_name, c.sector, sa.avg_close
FROM stock_avg AS sa
INNER JOIN companies AS c ON sa.ticker = c.ticker
ORDER BY sa.avg_close DESC;

-- CTE: find stocks beating their own sector average
WITH sector_avg AS (
    SELECT c.sector, AVG(sp.close_price) AS sector_close_avg
    FROM stock_prices AS sp
    INNER JOIN companies AS c ON sp.ticker = c.ticker
    GROUP BY c.sector
),
stock_avg AS (
    SELECT ticker, AVG(close_price) AS avg_close
    FROM stock_prices
    GROUP BY ticker
)
SELECT c.company_name, c.sector, 
       sa.avg_close        AS stock_avg,
       sea.sector_close_avg AS sector_avg
FROM stock_avg AS sa
INNER JOIN companies AS c   ON sa.ticker = c.ticker
INNER JOIN sector_avg AS sea ON c.sector = sea.sector
WHERE sa.avg_close > sea.sector_close_avg;



-- PHASE 5: Window Functions

-- RANK: rank each stock by its average closing price
SELECT 
    c.company_name,
    c.sector,
    AVG(sp.close_price) AS avg_close,
    RANK() OVER (ORDER BY AVG(sp.close_price) DESC) AS price_rank
FROM stock_prices sp
JOIN companies c ON sp.ticker = c.ticker
GROUP BY c.company_name, c.sector;

-- RANK within sector: which stock is #1 in its own sector?
SELECT 
    c.company_name,
    c.sector,
    sp.close_price,
    sp.price_date,
    RANK() OVER (PARTITION BY c.sector ORDER BY sp.close_price DESC) AS rank_in_sector
FROM stock_prices sp
JOIN companies c ON sp.ticker = c.ticker;

-- LAG: show yesterday's price next to today's price
SELECT
    ticker,
    price_date,
    close_price,
    LAG(close_price) OVER (PARTITION BY ticker ORDER BY price_date) AS prev_day_close
FROM stock_prices;

-- Daily % change using LAG
SELECT
    ticker,
    price_date,
    close_price,
    LAG(close_price) OVER (PARTITION BY ticker ORDER BY price_date) AS prev_close,
    ROUND(
        (close_price - LAG(close_price) OVER (PARTITION BY ticker ORDER BY price_date))
        / LAG(close_price) OVER (PARTITION BY ticker ORDER BY price_date) * 100
    , 2) AS pct_change
FROM stock_prices;

-- Running total of volume traded per stock
SELECT
    ticker,
    price_date,
    volume,
    SUM(volume) OVER (PARTITION BY ticker ORDER BY price_date) AS cumulative_volume
FROM stock_prices;




-- What is each stock's rank by closing price?
SELECT 
    ticker,
    close_price,
    RANK() OVER (ORDER BY close_price DESC) AS my_rank
FROM stock_prices;


-- Rank prices but restart ranking for each ticker separately
SELECT 
    ticker,
    price_date,
    close_price,
    RANK() OVER (PARTITION BY ticker ORDER BY close_price DESC) AS rank_per_stock
FROM stock_prices;


-- Show previous day's closing price next to today's
SELECT
    ticker,
    price_date,
    close_price,
    LAG(close_price) OVER (PARTITION BY ticker ORDER BY price_date) AS yesterday_close
FROM stock_prices;




-- FINAL PROJECT: Stock Market Analyst Report
-- Combines: JOINs + Aggregation + CTE + Window Functions

WITH stock_summary AS (
    SELECT
        sp.ticker,
        c.company_name,
        c.sector,
        AVG(sp.close_price)                                               AS avg_close,
        MAX(sp.close_price)                                               AS best_price,
        MIN(sp.close_price)                                               AS worst_price,
        SUM(sp.volume)                                                    AS total_volume,
        RANK() OVER (ORDER BY AVG(sp.close_price) DESC)                   AS overall_rank,
        RANK() OVER (PARTITION BY c.sector ORDER BY AVG(sp.close_price) DESC) AS sector_rank
    FROM stock_prices sp
    JOIN companies c ON sp.ticker = c.ticker
    GROUP BY sp.ticker, c.company_name, c.sector
)
SELECT
    overall_rank,
    sector_rank,
    company_name,
    sector,
    avg_close,
    best_price,
    worst_price,
    total_volume
FROM stock_summary
ORDER BY overall_rank;