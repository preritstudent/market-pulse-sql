USE StockMarket;

-- ============================================================
-- MARKET PULSE SQL — Full Analysis File
-- Updated to use real 1-year OHLCV data from Yahoo Finance
-- Tables: companies (5 rows) + StockPrices (1,255 rows)
-- Stocks: AAPL, TSLA, MSFT, GOOGL, AMZN
-- ============================================================

-- Quick sanity check before running
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';


-- ============================================================
-- PHASE 1: Basic SELECT, WHERE, Filtering
-- ============================================================

-- See all companies
SELECT * FROM companies;

-- See all price data (1,255 rows of real data)
SELECT * FROM StockPrices;

-- Only Apple prices
SELECT * FROM StockPrices
WHERE Ticker = 'AAPL';

-- Only closing prices for Tesla
SELECT Ticker, Date, [Close]
FROM StockPrices
WHERE Ticker = 'TSLA';

-- Which companies are in the Automotive sector?
SELECT company_name, country
FROM companies
WHERE sector = 'Automotive';

-- Latest 10 rows of data
SELECT TOP 10 * FROM StockPrices
ORDER BY Date DESC;


-- ============================================================
-- PHASE 2: Sorting & Aggregation
-- ============================================================

-- Which stock had the highest closing price ever?
SELECT Ticker, Date, [Close]
FROM StockPrices
ORDER BY [Close] DESC;

-- Which stock had the highest opening price ever?
SELECT Ticker, Date, [Open]
FROM StockPrices
ORDER BY [Open] DESC;

-- Average closing price per stock (over 1 year)
SELECT Ticker, ROUND(AVG([Close]), 2) AS avg_close
FROM StockPrices
GROUP BY Ticker
ORDER BY avg_close DESC;

-- Best single-day closing price per stock
SELECT Ticker, MAX([Close]) AS best_close
FROM StockPrices
GROUP BY Ticker
ORDER BY best_close DESC;

-- Worst single-day closing price per stock
SELECT Ticker, MIN([Close]) AS worst_close
FROM StockPrices
GROUP BY Ticker
ORDER BY worst_close DESC;

-- Which day had the most total trading volume across all stocks?
SELECT Date, SUM(Volume) AS total_volume
FROM StockPrices
GROUP BY Date
ORDER BY total_volume DESC;

-- How many trading days of data do we have per stock?
SELECT Ticker, COUNT(*) AS trading_days
FROM StockPrices
GROUP BY Ticker;


-- ============================================================
-- PHASE 3: JOINs
-- ============================================================

-- Basic JOIN: show company name alongside its prices
SELECT c.company_name, c.sector, sp.Date, sp.[Close]
FROM StockPrices AS sp
INNER JOIN companies AS c ON sp.Ticker = c.ticker;

-- Country and high price
SELECT c.country, sp.High
FROM StockPrices AS sp
INNER JOIN companies AS c ON sp.Ticker = c.ticker;

-- Which sector had the highest average closing price?
SELECT c.sector, ROUND(AVG(sp.[Close]), 2) AS avg_close
FROM StockPrices AS sp
INNER JOIN companies AS c ON sp.Ticker = c.ticker
GROUP BY c.sector
ORDER BY avg_close DESC;

-- Full company name with their best single day price
SELECT c.company_name, MAX(sp.[Close]) AS best_price
FROM StockPrices AS sp
INNER JOIN companies AS c ON sp.Ticker = c.ticker
GROUP BY c.company_name
ORDER BY best_price DESC;

-- Show all companies even if they have NO price data (LEFT JOIN)
SELECT c.company_name, c.sector, sp.[Close], sp.Date
FROM companies AS c
LEFT JOIN StockPrices AS sp ON c.ticker = sp.Ticker;

-- Latest closing price per stock with full company name
SELECT c.company_name, c.sector, sp.Date, sp.[Close]
FROM StockPrices sp
INNER JOIN companies c ON sp.Ticker = c.ticker
WHERE sp.Date = (SELECT MAX(Date) FROM StockPrices)
ORDER BY sp.[Close] DESC;


-- ============================================================
-- PHASE 4: Subqueries & CTEs
-- ============================================================

-- SUBQUERY: stocks with closing price above overall market average
SELECT Ticker, Date, [Close]
FROM StockPrices
WHERE [Close] > (SELECT AVG([Close]) FROM StockPrices);

-- SUBQUERY: companies that have more than 100 days of price data
SELECT company_name, sector
FROM companies
WHERE ticker IN (
    SELECT Ticker
    FROM StockPrices
    GROUP BY Ticker
    HAVING COUNT(*) > 100
);

-- CTE: calculate each stock's average, then rank them
WITH stock_avg AS (
    SELECT Ticker, ROUND(AVG([Close]), 2) AS avg_close
    FROM StockPrices
    GROUP BY Ticker
)
SELECT c.company_name, c.sector, sa.avg_close
FROM stock_avg AS sa
INNER JOIN companies AS c ON sa.Ticker = c.ticker
ORDER BY sa.avg_close DESC;

-- CTE: find stocks beating their own sector average
WITH sector_avg AS (
    SELECT c.sector, AVG(sp.[Close]) AS sector_close_avg
    FROM StockPrices AS sp
    INNER JOIN companies AS c ON sp.Ticker = c.ticker
    GROUP BY c.sector
),
stock_avg AS (
    SELECT Ticker, AVG([Close]) AS avg_close
    FROM StockPrices
    GROUP BY Ticker
)
SELECT c.company_name, c.sector,
       ROUND(sa.avg_close, 2)         AS stock_avg,
       ROUND(sea.sector_close_avg, 2) AS sector_avg
FROM stock_avg AS sa
INNER JOIN companies AS c    ON sa.Ticker = c.ticker
INNER JOIN sector_avg AS sea ON c.sector  = sea.sector
WHERE sa.avg_close > sea.sector_close_avg;


-- ============================================================
-- PHASE 5: Window Functions
-- ============================================================

-- RANK: rank each stock by its average closing price
SELECT
    c.company_name,
    c.sector,
    ROUND(AVG(sp.[Close]), 2) AS avg_close,
    RANK() OVER (ORDER BY AVG(sp.[Close]) DESC) AS price_rank
FROM StockPrices sp
JOIN companies c ON sp.Ticker = c.ticker
GROUP BY c.company_name, c.sector;

-- RANK within sector: which stock is #1 in its own sector?
SELECT
    c.company_name,
    c.sector,
    sp.[Close],
    sp.Date,
    RANK() OVER (PARTITION BY c.sector ORDER BY sp.[Close] DESC) AS rank_in_sector
FROM StockPrices sp
JOIN companies c ON sp.Ticker = c.ticker;

-- LAG: show yesterday's price next to today's price
SELECT
    Ticker,
    Date,
    [Close],
    LAG([Close]) OVER (PARTITION BY Ticker ORDER BY Date) AS prev_day_close
FROM StockPrices;

-- Daily % change using LAG (real market volatility!)
SELECT
    Ticker,
    Date,
    [Close],
    LAG([Close]) OVER (PARTITION BY Ticker ORDER BY Date) AS prev_close,
    ROUND(
        ([Close] - LAG([Close]) OVER (PARTITION BY Ticker ORDER BY Date))
        / LAG([Close]) OVER (PARTITION BY Ticker ORDER BY Date) * 100
    , 2) AS pct_change
FROM StockPrices;

-- 30-day moving average per stock
SELECT
    Ticker,
    Date,
    [Close],
    ROUND(AVG([Close]) OVER (
        PARTITION BY Ticker
        ORDER BY Date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2) AS MA_30Day
FROM StockPrices
ORDER BY Ticker, Date;

-- Running total of volume traded per stock
SELECT
    Ticker,
    Date,
    Volume,
    SUM(Volume) OVER (PARTITION BY Ticker ORDER BY Date) AS cumulative_volume
FROM StockPrices;

-- Rank each day's closing price per stock (1 = highest ever)
SELECT
    Ticker,
    Date,
    [Close],
    RANK() OVER (PARTITION BY Ticker ORDER BY [Close] DESC) AS rank_per_stock
FROM StockPrices;

-- 52-week high and low per stock
SELECT
    Ticker,
    MAX(High)  AS week52_high,
    MIN(Low)   AS week52_low,
    MAX(High) - MIN(Low) AS price_range
FROM StockPrices
GROUP BY Ticker
ORDER BY price_range DESC;


-- ============================================================
-- FINAL PROJECT: Stock Market Analyst Report
-- Combines: JOINs + Aggregation + CTE + Window Functions
-- Running on 1,255 rows of REAL market data
-- ============================================================

WITH stock_summary AS (
    SELECT
        sp.Ticker,
        c.company_name,
        c.sector,
        ROUND(AVG(sp.[Close]), 2)                                              AS avg_close,
        MAX(sp.[Close])                                                         AS best_price,
        MIN(sp.[Close])                                                         AS worst_price,
        SUM(sp.Volume)                                                          AS total_volume,
        RANK() OVER (ORDER BY AVG(sp.[Close]) DESC)                             AS overall_rank,
        RANK() OVER (PARTITION BY c.sector ORDER BY AVG(sp.[Close]) DESC)       AS sector_rank
    FROM StockPrices sp
    JOIN companies c ON sp.Ticker = c.ticker
    GROUP BY sp.Ticker, c.company_name, c.sector
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
