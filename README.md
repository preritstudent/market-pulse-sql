# 📈 Market Pulse SQL

A stock market analytics project built from scratch using SQL Server.
Designed to demonstrate real-world data analyst skills through a 
finance domain dataset.

## 🗄️ Database Structure

**companies** — stores company info (ticker, name, sector, country)  
**stock_prices** — stores daily OHLCV data (open, high, low, close, volume)

## 📊 What This Project Covers

| Phase | Concept | What I Built |
|-------|---------|--------------|
| 1 | SELECT, WHERE, INSERT | Queried stock prices by ticker and date |
| 2 | GROUP BY, ORDER BY, Aggregations | Found top performing stocks by avg price |
| 3 | INNER JOIN, LEFT JOIN | Combined company info with price data |
| 4 | Subqueries, CTEs | Found stocks beating their sector average |
| 5 | Window Functions | Ranked stocks, calculated daily % change |

## 🏁 Final Output

A single analyst report query that returns every stock's:
- Overall performance rank
- Rank within its sector
- Average, best and worst closing price
- Total volume traded

## 🛠️ Tools Used

- SQL Server (MSSQL) via Docker
- VS Code with SQL Server extension

## 📁 File

`market_pulse_analysis.sql` — contains all queries from Phase 1 to final report
