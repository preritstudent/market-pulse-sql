-- Latest closing price with company name and sector

SELECT DB_NAME() AS CurrentDatabase;

USE StockMarket;
GO

SELECT TOP 5 * FROM StockPrices;

SELECT 
    c.company_name,
    c.sector,
    s.Date,
    s.[Close]
FROM StockPrices s
JOIN companies c ON s.Ticker = c.ticker
WHERE s.Date = (SELECT MAX(Date) FROM StockPrices)
ORDER BY s.[Close] DESC;
